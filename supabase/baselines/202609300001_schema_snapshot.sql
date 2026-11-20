-- Instantané du schéma public de shoptrack-mvp, sans données, 2026-09-30.
-- Pour initialiser un projet de test VIDE uniquement ; ne pas ajouter ce
-- fichier dans supabase/migrations/ ni l'appliquer sur la production.
-- La migration 202609300002 corrige ensuite le RLS des transferts.


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."apply_stock_movement"("p_movement_id" "uuid", "p_shop_id" "uuid", "p_product_id" "uuid", "p_quantity_delta" integer, "p_type" "text", "p_created_at" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  operation_inserted uuid;
  resulting_quantity integer;
begin
  if not public.is_shop_member(p_shop_id) then
    raise exception 'Accès refusé à cette boutique';
  end if;

  if not public.is_shop_owner(p_shop_id) then
    if p_type in ('sale', 'loss') and p_quantity_delta >= 0 then
      raise exception 'Une vente ou perte vendeur doit diminuer le stock';
    elsif p_type not in ('sale', 'loss', 'inventory_adjustment') then
      raise exception 'Opération de stock réservée au propriétaire';
    end if;
  end if;

  insert into public.stock_sync_operations (
    id, shop_id, product_id, quantity_delta, operation_type
  )
  values (
    p_movement_id, p_shop_id, p_product_id, p_quantity_delta, p_type
  )
  on conflict (id) do nothing
  returning id into operation_inserted;

  if operation_inserted is null then
    select quantity into resulting_quantity
    from public.products
    where id = p_product_id and shop_id = p_shop_id;
    return resulting_quantity;
  end if;

  update public.products
  set quantity = quantity + p_quantity_delta
  where id = p_product_id
    and shop_id = p_shop_id
    and quantity + p_quantity_delta >= 0
  returning quantity into resulting_quantity;

  if resulting_quantity is null then
    raise exception 'Stock insuffisant ou produit introuvable';
  end if;

  if p_type = 'recharge' then
    insert into public.stock_movements (
      id, shop_id, product_id, quantity, type, created_at
    )
    values (
      p_movement_id, p_shop_id, p_product_id, abs(p_quantity_delta), 'recharge',
      coalesce(p_created_at, now())
    )
    on conflict (id) do nothing;
  end if;

  return resulting_quantity;
end;
$$;


ALTER FUNCTION "public"."apply_stock_movement"("p_movement_id" "uuid", "p_shop_id" "uuid", "p_product_id" "uuid", "p_quantity_delta" integer, "p_type" "text", "p_created_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_shop_creator"("target_shop_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.shops
    where id = target_shop_id
      and owner_id = (select auth.uid())
  );
$$;


ALTER FUNCTION "public"."is_shop_creator"("target_shop_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_shop_member"("target_shop_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.shop_members
    where shop_id = target_shop_id
      and user_id = auth.uid()
  );
$$;


ALTER FUNCTION "public"."is_shop_member"("target_shop_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_shop_owner"("target_shop_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.shop_members
    where shop_id = target_shop_id
      and user_id = (select auth.uid())
      and role = 'owner'
  );
$$;


ALTER FUNCTION "public"."is_shop_owner"("target_shop_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verifier_cout_commande"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if new.cout_matiere is distinct from old.cout_matiere
     and not public.is_shop_owner(new.shop_id) then
    raise exception using
      errcode = '42501',
      message = 'Seule la propriétaire enregistre ce qu''une commande a coûté.';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."verifier_cout_commande"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verifier_montant_commande"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
declare
  net_encaisse bigint;
begin
  if new.montant_accepte is not distinct from old.montant_accepte then
    return new;
  end if;

  select
    coalesce(sum(montant) filter (where type_mouvement = 'paiement'), 0)
      - coalesce(sum(montant) filter (where type_mouvement = 'remboursement'), 0)
  into net_encaisse
  from public.paiements_commandes
  where dossier_id = old.id
    and shop_id = old.shop_id;

  if net_encaisse > 0
     and (new.montant_accepte is null or new.montant_accepte < net_encaisse) then
    raise exception using
      errcode = '23514',
      message = format(
        'Montant refusé : %s FCFA ont déjà été encaissés.',
        net_encaisse
      );
  end if;

  new.updated_at := now();
  return new;
end;
$$;


ALTER FUNCTION "public"."verifier_montant_commande"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verifier_paiement_commande"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  montant_du_dossier bigint;
  statut_du_dossier text;
  total_paye bigint;
  total_rembourse bigint;
  net_encaisse bigint;
begin
  select montant_accepte, statut
    into montant_du_dossier, statut_du_dossier
  from public.dossiers_commandes
  where id = new.dossier_id
    and shop_id = new.shop_id
  for update;

  if not found then
    raise exception using
      errcode = '23503',
      message = 'Dossier de commande introuvable pour cette boutique.';
  end if;

  -- Seul l'ENCAISSEMENT est fermé sur une commande annulée. Le remboursement
  -- reste ouvert : c'est la suite normale de l'annulation.
  if statut_du_dossier = 'annulee' and new.type_mouvement = 'paiement' then
    raise exception using
      errcode = '23514',
      message = 'Impossible d''encaisser sur une commande annulée.';
  end if;

  if montant_du_dossier is null then
    raise exception using
      errcode = '23514',
      message = 'Le montant accepté doit être fixé avant d''enregistrer un paiement.';
  end if;

  select
    coalesce(sum(montant) filter (where type_mouvement = 'paiement'), 0),
    coalesce(sum(montant) filter (where type_mouvement = 'remboursement'), 0)
  into total_paye, total_rembourse
  from public.paiements_commandes
  where dossier_id = new.dossier_id
    and shop_id = new.shop_id;

  net_encaisse := total_paye - total_rembourse;

  if new.type_mouvement = 'paiement'
     and net_encaisse + new.montant > montant_du_dossier then
    raise exception using
      errcode = '23514',
      message = format(
        'Paiement refusé : le montant dépasse le solde restant de %s FCFA.',
        montant_du_dossier - net_encaisse
      );
  end if;

  -- On ne rend jamais plus qu'on n'a reçu, annulée ou pas.
  if new.type_mouvement = 'remboursement'
     and new.montant > net_encaisse then
    raise exception using
      errcode = '23514',
      message = format(
        'Remboursement refusé : seulement %s FCFA ont été encaissés.',
        net_encaisse
      );
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."verifier_paiement_commande"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."cash_movements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shop_id" "uuid",
    "user_id" "uuid",
    "amount" numeric(12,0) NOT NULL,
    "type" "text",
    "category" "text",
    "note" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "cash_movements_type_check" CHECK (("type" = ANY (ARRAY['morning_balance'::"text", 'withdrawal'::"text", 'incoming'::"text", 'adjustment_in'::"text", 'adjustment_out'::"text"])))
);


ALTER TABLE "public"."cash_movements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."clients" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "nom" "text" NOT NULL,
    "telephone" "text",
    "whatsapp" "text",
    "adresse" "text",
    "note" "text",
    "created_by" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "clients_nom_check" CHECK (("length"(TRIM(BOTH FROM "nom")) > 0))
);


ALTER TABLE "public"."clients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cycle_losses" (
    "id" "uuid" NOT NULL,
    "cycle_id" "uuid" NOT NULL,
    "quantity" integer NOT NULL,
    "reason" "text" NOT NULL,
    "note" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "cycle_losses_quantity_check" CHECK (("quantity" > 0)),
    CONSTRAINT "cycle_losses_reason_check" CHECK (("reason" = ANY (ARRAY['casse'::"text", 'rongeurs'::"text", 'deterioration'::"text", 'autre'::"text"])))
);


ALTER TABLE "public"."cycle_losses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."daily_closings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shop_id" "uuid",
    "user_id" "uuid",
    "closing_date" "date" NOT NULL,
    "morning_balance" numeric(12,0) NOT NULL,
    "total_sales" numeric(12,0) NOT NULL,
    "total_withdrawals" numeric(12,0) NOT NULL,
    "calculated_cash" numeric(12,0) NOT NULL,
    "gross_profit" numeric(12,0) NOT NULL,
    "net_profit" numeric(12,0) NOT NULL,
    "physical_cash" numeric(12,0),
    "cash_gap" numeric(12,0),
    "is_closed" boolean DEFAULT false,
    "closed_at" timestamp with time zone,
    "note" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."daily_closings" OWNER TO "postgres";


COMMENT ON COLUMN "public"."daily_closings"."closed_at" IS 'Instant réel du comptage. Frontière à partir de laquelle l''argent compte pour le lendemain. Nul sur les clôtures antérieures au 03/09/2026.';



CREATE TABLE IF NOT EXISTS "public"."dossiers_commandes" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "categorie" "text" NOT NULL,
    "description" "text" NOT NULL,
    "details" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "montant_accepte" bigint,
    "date_prevue" timestamp with time zone,
    "statut" "text" DEFAULT 'demande'::"text" NOT NULL,
    "motif_annulation" "text",
    "annule_at" timestamp with time zone,
    "annule_par" "uuid",
    "created_by" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "cout_matiere" bigint,
    "livree_at" timestamp with time zone,
    CONSTRAINT "dossiers_commandes_annulation_coherente_check" CHECK (((("statut" = 'annulee'::"text") AND ("annule_at" IS NOT NULL) AND ("annule_par" IS NOT NULL)) OR (("statut" <> 'annulee'::"text") AND ("annule_at" IS NULL) AND ("annule_par" IS NULL)))),
    CONSTRAINT "dossiers_commandes_categorie_check" CHECK (("categorie" = ANY (ARRAY['gateau'::"text", 'objet_decoratif'::"text", 'formation'::"text", 'decoration_evenementielle'::"text"]))),
    CONSTRAINT "dossiers_commandes_cout_matiere_check" CHECK ((("cout_matiere" IS NULL) OR ("cout_matiere" >= 0))),
    CONSTRAINT "dossiers_commandes_description_check" CHECK (("length"(TRIM(BOTH FROM "description")) > 0)),
    CONSTRAINT "dossiers_commandes_details_check" CHECK (("jsonb_typeof"("details") = 'object'::"text")),
    CONSTRAINT "dossiers_commandes_montant_accepte_check" CHECK (("montant_accepte" >= 0)),
    CONSTRAINT "dossiers_commandes_montant_selon_statut_check" CHECK ((("statut" = ANY (ARRAY['demande'::"text", 'annulee'::"text"])) OR ("montant_accepte" IS NOT NULL))),
    CONSTRAINT "dossiers_commandes_statut_check" CHECK (("statut" = ANY (ARRAY['demande'::"text", 'devis'::"text", 'confirmee'::"text", 'en_cours'::"text", 'prete'::"text", 'terminee'::"text", 'annulee'::"text"])))
);


ALTER TABLE "public"."dossiers_commandes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."dossiers_commandes"."cout_matiere" IS 'Ce que la commande a coûté, saisi à la livraison par la propriétaire. Nul = pas encore renseigné, jamais zéro.';



COMMENT ON COLUMN "public"."dossiers_commandes"."livree_at" IS 'Jour de la livraison réelle. C''est la date qui compte pour le bilan, jamais date_prevue.';



CREATE TABLE IF NOT EXISTS "public"."paiements_commandes" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "dossier_id" "uuid" NOT NULL,
    "type_mouvement" "text" NOT NULL,
    "montant" bigint NOT NULL,
    "mode_paiement" "text" DEFAULT 'especes'::"text" NOT NULL,
    "reference_externe" "text",
    "note" "text",
    "effectue_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "paiements_commandes_mode_paiement_check" CHECK (("mode_paiement" = ANY (ARRAY['especes'::"text", 'mtn_momo'::"text", 'orange_money'::"text", 'autre'::"text"]))),
    CONSTRAINT "paiements_commandes_montant_check" CHECK (("montant" > 0)),
    CONSTRAINT "paiements_commandes_type_mouvement_check" CHECK (("type_mouvement" = ANY (ARRAY['paiement'::"text", 'remboursement'::"text"])))
);


ALTER TABLE "public"."paiements_commandes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."paiements_commandes"."mode_paiement" IS 'Seules les espèces alimentent la caisse physique ; MTN MoMo et Orange Money restent des encaissements hors caisse.';



CREATE OR REPLACE VIEW "public"."dossiers_commandes_avec_solde" WITH ("security_invoker"='true') AS
 SELECT "dossier"."id",
    "dossier"."shop_id",
    "dossier"."client_id",
    "dossier"."categorie",
    "dossier"."description",
    "dossier"."details",
    "dossier"."montant_accepte",
    "dossier"."date_prevue",
    "dossier"."statut",
    "dossier"."motif_annulation",
    "dossier"."annule_at",
    "dossier"."annule_par",
    "dossier"."created_by",
    "dossier"."created_at",
    "dossier"."updated_at",
    "finances"."total_paye",
    "finances"."total_rembourse",
    ("finances"."total_paye" - "finances"."total_rembourse") AS "montant_net_encaisse",
        CASE
            WHEN ("dossier"."montant_accepte" IS NULL) THEN NULL::numeric
            ELSE (("dossier"."montant_accepte")::numeric - ("finances"."total_paye" - "finances"."total_rembourse"))
        END AS "solde"
   FROM ("public"."dossiers_commandes" "dossier"
     CROSS JOIN LATERAL ( SELECT COALESCE("sum"("paiement"."montant") FILTER (WHERE ("paiement"."type_mouvement" = 'paiement'::"text")), (0)::numeric) AS "total_paye",
            COALESCE("sum"("paiement"."montant") FILTER (WHERE ("paiement"."type_mouvement" = 'remboursement'::"text")), (0)::numeric) AS "total_rembourse"
           FROM "public"."paiements_commandes" "paiement"
          WHERE ("paiement"."dossier_id" = "dossier"."id")) "finances");


ALTER VIEW "public"."dossiers_commandes_avec_solde" OWNER TO "postgres";


COMMENT ON VIEW "public"."dossiers_commandes_avec_solde" IS 'Le devis ne vaut jamais recette : seuls paiements moins remboursements sont encaissés.';



CREATE TABLE IF NOT EXISTS "public"."inventory_counts" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "counted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "counted_quantity" integer NOT NULL,
    "previous_counted_at" timestamp with time zone,
    "previous_quantity" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_counts_counted_quantity_check" CHECK (("counted_quantity" >= 0))
);


ALTER TABLE "public"."inventory_counts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_losses" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "quantity" integer NOT NULL,
    "reason" "text" NOT NULL,
    "note" "text",
    "occurred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_losses_quantity_check" CHECK (("quantity" > 0)),
    CONSTRAINT "inventory_losses_reason_check" CHECK (("reason" = ANY (ARRAY['casse'::"text", 'peremption'::"text", 'invendu'::"text", 'vol'::"text", 'autre'::"text"])))
);


ALTER TABLE "public"."inventory_losses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_prices" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "buy_price" numeric NOT NULL,
    "sell_price" numeric NOT NULL,
    "effective_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "product_prices_buy_price_check" CHECK (("buy_price" >= (0)::numeric)),
    CONSTRAINT "product_prices_sell_price_check" CHECK (("sell_price" >= (0)::numeric))
);


ALTER TABLE "public"."product_prices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_units" (
    "id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "unit_name" "text" NOT NULL,
    "ratio_to_base" integer NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "product_units_ratio_to_base_check" CHECK (("ratio_to_base" > 0))
);


ALTER TABLE "public"."product_units" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shop_id" "uuid",
    "name" "text" NOT NULL,
    "buy_price" numeric(12,0) NOT NULL,
    "sell_price" numeric(12,0) NOT NULL,
    "quantity" integer DEFAULT 0,
    "min_quantity" integer DEFAULT 2,
    "barcode" "text",
    "photo_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "unit" "text",
    "archived_at" timestamp with time zone,
    "is_ingredient" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."products" OWNER TO "postgres";


COMMENT ON COLUMN "public"."products"."archived_at" IS 'Renseignée = produit au placard : masqué du stock, du comptage et de la vente, mais toujours cité par les périodes closes.';



COMMENT ON COLUMN "public"."products"."is_ingredient" IS 'Matière première : entre dans le coût d''une commande, ne se vend pas au comptoir.';



CREATE TABLE IF NOT EXISTS "public"."sale_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid",
    "product_id" "uuid",
    "product_name" "text" NOT NULL,
    "quantity" integer NOT NULL,
    "sell_price" numeric(12,0) NOT NULL,
    "buy_price" numeric(12,0) NOT NULL,
    "profit" numeric(12,0) NOT NULL,
    "cycle_id" "uuid",
    "unit_id" "uuid",
    "quantity_in_base" integer,
    "unit_sell_price" numeric
);


ALTER TABLE "public"."sale_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sales" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shop_id" "uuid",
    "user_id" "uuid",
    "total_amount" numeric(12,0) NOT NULL,
    "total_profit" numeric(12,0) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."sales" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shop_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shop_id" "uuid",
    "user_id" "uuid",
    "role" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "shop_members_role_check" CHECK (("role" = ANY (ARRAY['owner'::"text", 'seller'::"text"])))
);


ALTER TABLE "public"."shop_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shop_settings" (
    "shop_id" "uuid" NOT NULL,
    "unit_mode" "text" DEFAULT 'simple'::"text" NOT NULL,
    "sale_capture_mode" "text" DEFAULT 'realtime'::"text" NOT NULL,
    "multi_point_enabled" boolean DEFAULT false NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "commandes_enabled" boolean DEFAULT false NOT NULL,
    CONSTRAINT "shop_settings_sale_capture_mode_check" CHECK (("sale_capture_mode" = ANY (ARRAY['realtime'::"text", 'periodic'::"text"]))),
    CONSTRAINT "shop_settings_unit_mode_check" CHECK (("unit_mode" = ANY (ARRAY['simple'::"text", 'hierarchical'::"text"])))
);


ALTER TABLE "public"."shop_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shop_takings" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "date" "date" NOT NULL,
    "amount" numeric NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "shop_takings_amount_check" CHECK (("amount" >= (0)::numeric))
);


ALTER TABLE "public"."shop_takings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shops" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "owner_id" "uuid",
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "abonnement_actif" boolean DEFAULT true NOT NULL,
    "abonnement_jusqu_au" "date",
    "abonnement_note" "text"
);


ALTER TABLE "public"."shops" OWNER TO "postgres";


COMMENT ON COLUMN "public"."shops"."abonnement_actif" IS 'Faux = abonnement suspendu. Aucun effet tant que la vérification n''est pas branchée.';



COMMENT ON COLUMN "public"."shops"."abonnement_jusqu_au" IS 'Dernier jour couvert par le paiement. Null = jamais payé, ou période d''essai.';



COMMENT ON COLUMN "public"."shops"."abonnement_note" IS 'Trace libre : moyen de paiement, montant, date de réception.';



CREATE TABLE IF NOT EXISTS "public"."stock_movements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shop_id" "uuid",
    "product_id" "uuid",
    "quantity" integer NOT NULL,
    "type" "text",
    "note" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "stock_movements_type_check" CHECK (("type" = ANY (ARRAY['recharge'::"text", 'adjustment'::"text"])))
);


ALTER TABLE "public"."stock_movements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stock_purchases" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "quantity" integer NOT NULL,
    "unit_cost" numeric NOT NULL,
    "purchased_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "note" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "stock_purchases_quantity_check" CHECK (("quantity" > 0)),
    CONSTRAINT "stock_purchases_unit_cost_check" CHECK (("unit_cost" >= (0)::numeric))
);


ALTER TABLE "public"."stock_purchases" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stock_sync_operations" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "quantity_delta" integer NOT NULL,
    "operation_type" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."stock_sync_operations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stock_transfers" (
    "id" "uuid" NOT NULL,
    "from_shop_id" "uuid" NOT NULL,
    "to_shop_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "quantity" integer NOT NULL,
    "received_quantity" integer,
    "received_at" timestamp with time zone,
    "transferred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "note" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "product_name" "text",
    "buy_price" numeric,
    "sell_price" numeric,
    "unit" "text",
    "cancelled_at" timestamp with time zone,
    "from_shop_name" "text",
    "to_shop_name" "text",
    CONSTRAINT "stock_transfers_check" CHECK (("from_shop_id" <> "to_shop_id")),
    CONSTRAINT "stock_transfers_quantity_check" CHECK (("quantity" > 0)),
    CONSTRAINT "stock_transfers_received_quantity_check" CHECK (("received_quantity" >= 0))
);


ALTER TABLE "public"."stock_transfers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."supply_cycles" (
    "id" "uuid" NOT NULL,
    "shop_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "opened_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "closed_at" timestamp with time zone,
    "quantity_received" integer NOT NULL,
    "purchase_cost" numeric NOT NULL,
    "reference_margin_per_unit" numeric,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "supply_cycles_purchase_cost_check" CHECK (("purchase_cost" >= (0)::numeric)),
    CONSTRAINT "supply_cycles_quantity_received_check" CHECK (("quantity_received" >= 0)),
    CONSTRAINT "supply_cycles_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'closed'::"text"])))
);


ALTER TABLE "public"."supply_cycles" OWNER TO "postgres";


ALTER TABLE ONLY "public"."cash_movements"
    ADD CONSTRAINT "cash_movements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "clients_id_shop_unique" UNIQUE ("id", "shop_id");



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "clients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cycle_losses"
    ADD CONSTRAINT "cycle_losses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."daily_closings"
    ADD CONSTRAINT "daily_closings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."daily_closings"
    ADD CONSTRAINT "daily_closings_shop_id_closing_date_key" UNIQUE ("shop_id", "closing_date");



ALTER TABLE ONLY "public"."dossiers_commandes"
    ADD CONSTRAINT "dossiers_commandes_id_shop_unique" UNIQUE ("id", "shop_id");



ALTER TABLE ONLY "public"."dossiers_commandes"
    ADD CONSTRAINT "dossiers_commandes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_counts"
    ADD CONSTRAINT "inventory_counts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_losses"
    ADD CONSTRAINT "inventory_losses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."paiements_commandes"
    ADD CONSTRAINT "paiements_commandes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_prices"
    ADD CONSTRAINT "product_prices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_units"
    ADD CONSTRAINT "product_units_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shop_members"
    ADD CONSTRAINT "shop_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shop_settings"
    ADD CONSTRAINT "shop_settings_pkey" PRIMARY KEY ("shop_id");



ALTER TABLE ONLY "public"."shop_takings"
    ADD CONSTRAINT "shop_takings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shop_takings"
    ADD CONSTRAINT "shop_takings_shop_id_date_key" UNIQUE ("shop_id", "date");



ALTER TABLE ONLY "public"."shops"
    ADD CONSTRAINT "shops_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_purchases"
    ADD CONSTRAINT "stock_purchases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_sync_operations"
    ADD CONSTRAINT "stock_sync_operations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_transfers"
    ADD CONSTRAINT "stock_transfers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."supply_cycles"
    ADD CONSTRAINT "supply_cycles_pkey" PRIMARY KEY ("id");



CREATE INDEX "clients_shop_nom_idx" ON "public"."clients" USING "btree" ("shop_id", "nom");



CREATE INDEX "clients_shop_telephone_idx" ON "public"."clients" USING "btree" ("shop_id", "telephone") WHERE ("telephone" IS NOT NULL);



CREATE UNIQUE INDEX "daily_closings_shop_date_key" ON "public"."daily_closings" USING "btree" ("shop_id", "closing_date");



CREATE INDEX "dossiers_commandes_client_idx" ON "public"."dossiers_commandes" USING "btree" ("client_id", "created_at" DESC);



CREATE INDEX "dossiers_commandes_shop_statut_date_idx" ON "public"."dossiers_commandes" USING "btree" ("shop_id", "statut", "date_prevue");



CREATE INDEX "inventory_counts_shop_product_date" ON "public"."inventory_counts" USING "btree" ("shop_id", "product_id", "counted_at");



CREATE INDEX "inventory_losses_shop_product_date" ON "public"."inventory_losses" USING "btree" ("shop_id", "product_id", "occurred_at");



CREATE INDEX "paiements_commandes_dossier_date_idx" ON "public"."paiements_commandes" USING "btree" ("dossier_id", "effectue_at");



CREATE INDEX "paiements_commandes_shop_date_idx" ON "public"."paiements_commandes" USING "btree" ("shop_id", "effectue_at");



CREATE INDEX "product_prices_shop_product_date" ON "public"."product_prices" USING "btree" ("shop_id", "product_id", "effective_at");



CREATE INDEX "products_shop_active_idx" ON "public"."products" USING "btree" ("shop_id") WHERE ("archived_at" IS NULL);



CREATE UNIQUE INDEX "products_shop_barcode_key" ON "public"."products" USING "btree" ("shop_id", "barcode") WHERE (("barcode" IS NOT NULL) AND ("btrim"("barcode") <> ''::"text"));



CREATE UNIQUE INDEX "shop_members_shop_user_key" ON "public"."shop_members" USING "btree" ("shop_id", "user_id");



CREATE UNIQUE INDEX "stock_movements_id_key" ON "public"."stock_movements" USING "btree" ("id");



CREATE INDEX "stock_purchases_shop_product_date" ON "public"."stock_purchases" USING "btree" ("shop_id", "product_id", "purchased_at");



CREATE INDEX "stock_transfers_from_date" ON "public"."stock_transfers" USING "btree" ("from_shop_id", "transferred_at");



CREATE INDEX "stock_transfers_to_date" ON "public"."stock_transfers" USING "btree" ("to_shop_id", "transferred_at");



CREATE OR REPLACE TRIGGER "verifier_cout_commande" BEFORE UPDATE ON "public"."dossiers_commandes" FOR EACH ROW EXECUTE FUNCTION "public"."verifier_cout_commande"();



CREATE OR REPLACE TRIGGER "verifier_montant_commande_before_update" BEFORE UPDATE OF "montant_accepte" ON "public"."dossiers_commandes" FOR EACH ROW EXECUTE FUNCTION "public"."verifier_montant_commande"();



CREATE OR REPLACE TRIGGER "verifier_paiement_commande_before_insert" BEFORE INSERT ON "public"."paiements_commandes" FOR EACH ROW EXECUTE FUNCTION "public"."verifier_paiement_commande"();



ALTER TABLE ONLY "public"."cash_movements"
    ADD CONSTRAINT "cash_movements_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cash_movements"
    ADD CONSTRAINT "cash_movements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "clients_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cycle_losses"
    ADD CONSTRAINT "cycle_losses_cycle_id_fkey" FOREIGN KEY ("cycle_id") REFERENCES "public"."supply_cycles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."daily_closings"
    ADD CONSTRAINT "daily_closings_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."daily_closings"
    ADD CONSTRAINT "daily_closings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."dossiers_commandes"
    ADD CONSTRAINT "dossiers_commandes_client_same_shop_fk" FOREIGN KEY ("client_id", "shop_id") REFERENCES "public"."clients"("id", "shop_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."dossiers_commandes"
    ADD CONSTRAINT "dossiers_commandes_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_counts"
    ADD CONSTRAINT "inventory_counts_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_counts"
    ADD CONSTRAINT "inventory_counts_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_losses"
    ADD CONSTRAINT "inventory_losses_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory_losses"
    ADD CONSTRAINT "inventory_losses_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."paiements_commandes"
    ADD CONSTRAINT "paiements_commandes_dossier_same_shop_fk" FOREIGN KEY ("dossier_id", "shop_id") REFERENCES "public"."dossiers_commandes"("id", "shop_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."paiements_commandes"
    ADD CONSTRAINT "paiements_commandes_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_prices"
    ADD CONSTRAINT "product_prices_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_prices"
    ADD CONSTRAINT "product_prices_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_units"
    ADD CONSTRAINT "product_units_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_cycle_id_fkey" FOREIGN KEY ("cycle_id") REFERENCES "public"."supply_cycles"("id");



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id");



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_unit_id_fkey" FOREIGN KEY ("unit_id") REFERENCES "public"."product_units"("id");



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."shop_members"
    ADD CONSTRAINT "shop_members_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shop_members"
    ADD CONSTRAINT "shop_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shop_settings"
    ADD CONSTRAINT "shop_settings_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shop_takings"
    ADD CONSTRAINT "shop_takings_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shops"
    ADD CONSTRAINT "shops_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_purchases"
    ADD CONSTRAINT "stock_purchases_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_purchases"
    ADD CONSTRAINT "stock_purchases_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_sync_operations"
    ADD CONSTRAINT "stock_sync_operations_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_sync_operations"
    ADD CONSTRAINT "stock_sync_operations_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_transfers"
    ADD CONSTRAINT "stock_transfers_from_shop_id_fkey" FOREIGN KEY ("from_shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_transfers"
    ADD CONSTRAINT "stock_transfers_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_transfers"
    ADD CONSTRAINT "stock_transfers_to_shop_id_fkey" FOREIGN KEY ("to_shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."supply_cycles"
    ADD CONSTRAINT "supply_cycles_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."supply_cycles"
    ADD CONSTRAINT "supply_cycles_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "public"."shops"("id") ON DELETE CASCADE;



CREATE POLICY "allow_insert_shops" ON "public"."shops" FOR INSERT WITH CHECK (("auth"."uid"() = "owner_id"));



CREATE POLICY "allow_select_shops" ON "public"."shops" FOR SELECT USING (("auth"."uid"() = "owner_id"));



ALTER TABLE "public"."cash_movements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."clients" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cycle_losses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."daily_closings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dossiers_commandes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inventory_counts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inventory_losses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."paiements_commandes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."product_prices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."product_units" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sale_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sales" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shop_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shop_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shop_takings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shops" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "shoptrack_cash_member_read" ON "public"."cash_movements" FOR SELECT TO "authenticated" USING ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_cash_owner_all" ON "public"."cash_movements" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_cash_seller_insert" ON "public"."cash_movements" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_cash_seller_update" ON "public"."cash_movements" FOR UPDATE TO "authenticated" USING ("public"."is_shop_member"("shop_id")) WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_clients_member_insert" ON "public"."clients" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_shop_member"("shop_id") AND ("created_by" = ( SELECT "auth"."uid"() AS "uid"))));



CREATE POLICY "shoptrack_clients_member_read" ON "public"."clients" FOR SELECT TO "authenticated" USING ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_clients_member_update" ON "public"."clients" FOR UPDATE TO "authenticated" USING ("public"."is_shop_member"("shop_id")) WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_clients_owner_all" ON "public"."clients" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_closings_member_read" ON "public"."daily_closings" FOR SELECT TO "authenticated" USING ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_closings_owner_all" ON "public"."daily_closings" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_closings_seller_insert" ON "public"."daily_closings" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_closings_seller_update" ON "public"."daily_closings" FOR UPDATE TO "authenticated" USING ("public"."is_shop_member"("shop_id")) WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_cycle_losses_owner_all" ON "public"."cycle_losses" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."supply_cycles"
  WHERE (("supply_cycles"."id" = "cycle_losses"."cycle_id") AND "public"."is_shop_owner"("supply_cycles"."shop_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."supply_cycles"
  WHERE (("supply_cycles"."id" = "cycle_losses"."cycle_id") AND "public"."is_shop_owner"("supply_cycles"."shop_id")))));



CREATE POLICY "shoptrack_dossiers_commandes_member_insert" ON "public"."dossiers_commandes" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_shop_member"("shop_id") AND ("created_by" = ( SELECT "auth"."uid"() AS "uid")) AND ("montant_accepte" IS NULL) AND ("statut" = 'demande'::"text") AND ("motif_annulation" IS NULL) AND ("annule_at" IS NULL) AND ("annule_par" IS NULL)));



CREATE POLICY "shoptrack_dossiers_commandes_member_read" ON "public"."dossiers_commandes" FOR SELECT TO "authenticated" USING ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_dossiers_commandes_member_update" ON "public"."dossiers_commandes" FOR UPDATE TO "authenticated" USING (("public"."is_shop_member"("shop_id") AND ("statut" <> 'annulee'::"text") AND ("categorie" <> 'decoration_evenementielle'::"text"))) WITH CHECK (("public"."is_shop_member"("shop_id") AND ("statut" <> 'annulee'::"text") AND ("categorie" <> 'decoration_evenementielle'::"text") AND ("motif_annulation" IS NULL) AND ("annule_at" IS NULL) AND ("annule_par" IS NULL)));



CREATE POLICY "shoptrack_dossiers_commandes_owner_all" ON "public"."dossiers_commandes" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_inventory_counts_members" ON "public"."inventory_counts" TO "authenticated" USING ("public"."is_shop_member"("shop_id")) WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_inventory_losses_members" ON "public"."inventory_losses" TO "authenticated" USING ("public"."is_shop_member"("shop_id")) WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_members_owner_manage" ON "public"."shop_members" TO "authenticated" USING (("public"."is_shop_owner"("shop_id") OR ("user_id" = "auth"."uid"()))) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_members_self_on_own_shop" ON "public"."shop_members" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND "public"."is_shop_creator"("shop_id")));



CREATE POLICY "shoptrack_paiements_commandes_member_insert" ON "public"."paiements_commandes" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_shop_member"("shop_id") AND ("created_by" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM "public"."dossiers_commandes" "d"
  WHERE (("d"."id" = "paiements_commandes"."dossier_id") AND ("d"."shop_id" = "paiements_commandes"."shop_id") AND ("d"."statut" <> 'annulee'::"text") AND (("paiements_commandes"."type_mouvement" = 'paiement'::"text") OR ("d"."statut" <> 'terminee'::"text")))))));



CREATE POLICY "shoptrack_paiements_commandes_member_read" ON "public"."paiements_commandes" FOR SELECT TO "authenticated" USING ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_paiements_commandes_owner_all" ON "public"."paiements_commandes" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_product_prices_owner_all" ON "public"."product_prices" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_product_units_member_read" ON "public"."product_units" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."products"
  WHERE (("products"."id" = "product_units"."product_id") AND "public"."is_shop_member"("products"."shop_id")))));



CREATE POLICY "shoptrack_product_units_owner_write" ON "public"."product_units" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."products"
  WHERE (("products"."id" = "product_units"."product_id") AND "public"."is_shop_owner"("products"."shop_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."products"
  WHERE (("products"."id" = "product_units"."product_id") AND "public"."is_shop_owner"("products"."shop_id")))));



CREATE POLICY "shoptrack_products_member_read" ON "public"."products" FOR SELECT TO "authenticated" USING ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_products_owner_write" ON "public"."products" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_sale_items_members" ON "public"."sale_items" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."sales"
  WHERE (("sales"."id" = "sale_items"."sale_id") AND "public"."is_shop_member"("sales"."shop_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."sales"
  WHERE (("sales"."id" = "sale_items"."sale_id") AND "public"."is_shop_member"("sales"."shop_id")))));



CREATE POLICY "shoptrack_sales_members" ON "public"."sales" TO "authenticated" USING ("public"."is_shop_member"("shop_id")) WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_shop_settings_member_read" ON "public"."shop_settings" FOR SELECT TO "authenticated" USING ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_shop_settings_owner_write" ON "public"."shop_settings" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_shop_takings_members" ON "public"."shop_takings" TO "authenticated" USING ("public"."is_shop_member"("shop_id")) WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_shops_member_read" ON "public"."shops" FOR SELECT TO "authenticated" USING ("public"."is_shop_member"("id"));



CREATE POLICY "shoptrack_shops_owner_update" ON "public"."shops" FOR UPDATE TO "authenticated" USING ("public"."is_shop_owner"("id")) WITH CHECK ("public"."is_shop_owner"("id"));



CREATE POLICY "shoptrack_stock_members" ON "public"."stock_movements" TO "authenticated" USING ("public"."is_shop_member"("shop_id")) WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_stock_purchases_owner_all" ON "public"."stock_purchases" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



CREATE POLICY "shoptrack_stock_sync_members" ON "public"."stock_sync_operations" TO "authenticated" USING ("public"."is_shop_member"("shop_id")) WITH CHECK ("public"."is_shop_member"("shop_id"));



CREATE POLICY "shoptrack_stock_transfers_owner_all" ON "public"."stock_transfers" TO "authenticated" USING (("public"."is_shop_owner"("from_shop_id") OR "public"."is_shop_owner"("to_shop_id"))) WITH CHECK (("public"."is_shop_owner"("from_shop_id") OR "public"."is_shop_owner"("to_shop_id")));



CREATE POLICY "shoptrack_supply_cycles_owner_all" ON "public"."supply_cycles" TO "authenticated" USING ("public"."is_shop_owner"("shop_id")) WITH CHECK ("public"."is_shop_owner"("shop_id"));



ALTER TABLE "public"."stock_movements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stock_purchases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stock_sync_operations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stock_transfers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."supply_cycles" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



REVOKE ALL ON FUNCTION "public"."apply_stock_movement"("p_movement_id" "uuid", "p_shop_id" "uuid", "p_product_id" "uuid", "p_quantity_delta" integer, "p_type" "text", "p_created_at" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."apply_stock_movement"("p_movement_id" "uuid", "p_shop_id" "uuid", "p_product_id" "uuid", "p_quantity_delta" integer, "p_type" "text", "p_created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_stock_movement"("p_movement_id" "uuid", "p_shop_id" "uuid", "p_product_id" "uuid", "p_quantity_delta" integer, "p_type" "text", "p_created_at" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_shop_creator"("target_shop_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_shop_creator"("target_shop_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_shop_creator"("target_shop_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_shop_member"("target_shop_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_shop_member"("target_shop_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_shop_member"("target_shop_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_shop_owner"("target_shop_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_shop_owner"("target_shop_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_shop_owner"("target_shop_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."verifier_cout_commande"() TO "anon";
GRANT ALL ON FUNCTION "public"."verifier_cout_commande"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."verifier_cout_commande"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."verifier_montant_commande"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."verifier_montant_commande"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."verifier_paiement_commande"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."verifier_paiement_commande"() TO "service_role";



GRANT ALL ON TABLE "public"."cash_movements" TO "anon";
GRANT ALL ON TABLE "public"."cash_movements" TO "authenticated";
GRANT ALL ON TABLE "public"."cash_movements" TO "service_role";



GRANT ALL ON TABLE "public"."clients" TO "anon";
GRANT ALL ON TABLE "public"."clients" TO "authenticated";
GRANT ALL ON TABLE "public"."clients" TO "service_role";



GRANT ALL ON TABLE "public"."cycle_losses" TO "anon";
GRANT ALL ON TABLE "public"."cycle_losses" TO "authenticated";
GRANT ALL ON TABLE "public"."cycle_losses" TO "service_role";



GRANT ALL ON TABLE "public"."daily_closings" TO "anon";
GRANT ALL ON TABLE "public"."daily_closings" TO "authenticated";
GRANT ALL ON TABLE "public"."daily_closings" TO "service_role";



GRANT ALL ON TABLE "public"."dossiers_commandes" TO "anon";
GRANT ALL ON TABLE "public"."dossiers_commandes" TO "authenticated";
GRANT ALL ON TABLE "public"."dossiers_commandes" TO "service_role";



GRANT ALL ON TABLE "public"."paiements_commandes" TO "anon";
GRANT ALL ON TABLE "public"."paiements_commandes" TO "authenticated";
GRANT ALL ON TABLE "public"."paiements_commandes" TO "service_role";



GRANT ALL ON TABLE "public"."dossiers_commandes_avec_solde" TO "authenticated";
GRANT ALL ON TABLE "public"."dossiers_commandes_avec_solde" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_counts" TO "anon";
GRANT ALL ON TABLE "public"."inventory_counts" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_counts" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_losses" TO "anon";
GRANT ALL ON TABLE "public"."inventory_losses" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_losses" TO "service_role";



GRANT ALL ON TABLE "public"."product_prices" TO "anon";
GRANT ALL ON TABLE "public"."product_prices" TO "authenticated";
GRANT ALL ON TABLE "public"."product_prices" TO "service_role";



GRANT ALL ON TABLE "public"."product_units" TO "anon";
GRANT ALL ON TABLE "public"."product_units" TO "authenticated";
GRANT ALL ON TABLE "public"."product_units" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "anon";
GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON TABLE "public"."sale_items" TO "anon";
GRANT ALL ON TABLE "public"."sale_items" TO "authenticated";
GRANT ALL ON TABLE "public"."sale_items" TO "service_role";



GRANT ALL ON TABLE "public"."sales" TO "anon";
GRANT ALL ON TABLE "public"."sales" TO "authenticated";
GRANT ALL ON TABLE "public"."sales" TO "service_role";



GRANT ALL ON TABLE "public"."shop_members" TO "anon";
GRANT ALL ON TABLE "public"."shop_members" TO "authenticated";
GRANT ALL ON TABLE "public"."shop_members" TO "service_role";



GRANT ALL ON TABLE "public"."shop_settings" TO "anon";
GRANT ALL ON TABLE "public"."shop_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."shop_settings" TO "service_role";



GRANT ALL ON TABLE "public"."shop_takings" TO "anon";
GRANT ALL ON TABLE "public"."shop_takings" TO "authenticated";
GRANT ALL ON TABLE "public"."shop_takings" TO "service_role";



GRANT ALL ON TABLE "public"."shops" TO "anon";
GRANT ALL ON TABLE "public"."shops" TO "authenticated";
GRANT ALL ON TABLE "public"."shops" TO "service_role";



GRANT ALL ON TABLE "public"."stock_movements" TO "anon";
GRANT ALL ON TABLE "public"."stock_movements" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_movements" TO "service_role";



GRANT ALL ON TABLE "public"."stock_purchases" TO "anon";
GRANT ALL ON TABLE "public"."stock_purchases" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_purchases" TO "service_role";



GRANT ALL ON TABLE "public"."stock_sync_operations" TO "anon";
GRANT ALL ON TABLE "public"."stock_sync_operations" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_sync_operations" TO "service_role";



GRANT ALL ON TABLE "public"."stock_transfers" TO "anon";
GRANT ALL ON TABLE "public"."stock_transfers" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_transfers" TO "service_role";



GRANT ALL ON TABLE "public"."supply_cycles" TO "anon";
GRANT ALL ON TABLE "public"."supply_cycles" TO "authenticated";
GRANT ALL ON TABLE "public"."supply_cycles" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";





