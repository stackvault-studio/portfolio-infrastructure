


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


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."match_documents"("query_embedding" "extensions"."vector", "match_count" integer DEFAULT NULL::integer, "filter" "jsonb" DEFAULT '{}'::"jsonb") RETURNS TABLE("id" bigint, "content" "text", "metadata" "jsonb", "similarity" double precision)
    LANGUAGE "plpgsql"
    AS $$
#variable_conflict use_column
begin
  return query
  select
    id,
    content,
    metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;


ALTER FUNCTION "public"."match_documents"("query_embedding" "extensions"."vector", "match_count" integer, "filter" "jsonb") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."achievement" (
    "description_id" bigint,
    "education_id" bigint,
    "id" bigint NOT NULL,
    "project_id" bigint
);


ALTER TABLE "public"."achievement" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."achievement_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."achievement_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_providers" (
    "provider_name" "text" NOT NULL,
    "is_blocked" boolean DEFAULT false,
    "blocked_at" timestamp with time zone,
    "reset_at" timestamp with time zone,
    "total_requests" integer DEFAULT 0,
    "total_429s" integer DEFAULT 0
);


ALTER TABLE "public"."agent_providers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."agent_sessions" (
    "session_id" "text" NOT NULL,
    "user_ip" "text",
    "message_count" integer DEFAULT 0,
    "first_seen" timestamp with time zone DEFAULT "now"(),
    "last_active" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."agent_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."certification" (
    "expiry_date" "date",
    "issue_date" "date",
    "description_id" bigint,
    "id" bigint NOT NULL,
    "name_id" bigint,
    "badge_url" character varying(255),
    "issuer" character varying(255),
    "logo" character varying(255)
);


ALTER TABLE "public"."certification" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."certification_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."certification_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."certification_technologies" (
    "certification_id" bigint NOT NULL,
    "technologies_id" bigint NOT NULL
);


ALTER TABLE "public"."certification_technologies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."client" (
    "id" bigint NOT NULL,
    "logo" character varying(255),
    "name" character varying(255)
);


ALTER TABLE "public"."client" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."client_projects" (
    "client_id" bigint NOT NULL,
    "projects_id" bigint NOT NULL
);


ALTER TABLE "public"."client_projects" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."client_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."client_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."coursework" (
    "course_education_id" bigint,
    "id" bigint NOT NULL,
    "project_education_id" bigint,
    "title_id" bigint
);


ALTER TABLE "public"."coursework" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."coursework_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."coursework_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."document_metadata" (
    "id" "text" NOT NULL,
    "title" "text",
    "url" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "schema" "text"
);


ALTER TABLE "public"."document_metadata" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."document_rows" (
    "id" integer NOT NULL,
    "dataset_id" "text",
    "row_data" "jsonb"
);


ALTER TABLE "public"."document_rows" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."document_rows_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."document_rows_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."document_rows_id_seq" OWNED BY "public"."document_rows"."id";



CREATE TABLE IF NOT EXISTS "public"."documents_pg" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "text" "text",
    "metadata" "jsonb",
    "embedding" "extensions"."vector"
);


ALTER TABLE "public"."documents_pg" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."education" (
    "degree_id" bigint,
    "end_date" timestamp(6) with time zone,
    "gpa" bigint,
    "id" bigint NOT NULL,
    "location_id" bigint,
    "start_date" timestamp(6) with time zone,
    "institution" character varying(255)
);


ALTER TABLE "public"."education" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."education_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."education_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."location" (
    "city_id" bigint,
    "country_id" bigint,
    "id" bigint NOT NULL
);


ALTER TABLE "public"."location" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."location_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."location_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."n8n_chat_histories" (
    "id" integer NOT NULL,
    "session_id" character varying(255) NOT NULL,
    "message" "jsonb" NOT NULL
);


ALTER TABLE "public"."n8n_chat_histories" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."n8n_chat_histories_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."n8n_chat_histories_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."n8n_chat_histories_id_seq" OWNED BY "public"."n8n_chat_histories"."id";



CREATE SEQUENCE IF NOT EXISTS "public"."positions_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."positions_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project" (
    "team_size" character varying(255),
    "company_id" bigint,
    "end_date" timestamp(6) with time zone,
    "id" bigint NOT NULL,
    "project_description_id" bigint,
    "start_date" timestamp(6) with time zone,
    "methodology" character varying(255),
    "project_name" character varying(255),
    CONSTRAINT "project_methodology_check" CHECK ((("methodology")::"text" = ANY ((ARRAY['SCRUM'::character varying, 'KANBAN'::character varying, 'XP'::character varying, 'WATERFALL'::character varying, 'V_MODEL'::character varying, 'RAD'::character varying, 'RUP'::character varying, 'AGILE'::character varying, 'LEAN'::character varying, 'DEVOPS'::character varying, 'DSDM'::character varying, 'SAFe'::character varying, 'TDD'::character varying, 'BDD'::character varying, 'FDD'::character varying])::"text"[])))
);


ALTER TABLE "public"."project" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_client" (
    "project_id" bigint NOT NULL,
    "client_id" bigint NOT NULL
);


ALTER TABLE "public"."project_client" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_clients" (
    "project_id" bigint NOT NULL,
    "clients_id" bigint NOT NULL
);


ALTER TABLE "public"."project_clients" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."project_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."project_seq" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."projects_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."projects_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."responsibility" (
    "description_id" bigint,
    "id" bigint NOT NULL,
    "project_id" bigint,
    "project" "bytea"
);


ALTER TABLE "public"."responsibility" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."responsibility_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."responsibility_seq" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."technologies_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."technologies_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."technology_topic_rate" (
    "rate" numeric(38,2),
    "certification_id" bigint,
    "description_id" bigint,
    "id" bigint NOT NULL,
    "project_id" bigint,
    "covered_topic" character varying(255),
    "name" character varying(255),
    "technology" character varying(255)
);


ALTER TABLE "public"."technology_topic_rate" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."technology_topic_rate_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."technology_topic_rate_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."translation_string" (
    "id" bigint NOT NULL,
    "en" "text",
    "fr" "text"
);


ALTER TABLE "public"."translation_string" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."translation_string_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."translation_string_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."work_experience" (
    "active" boolean,
    "end_date" "date",
    "start_date" "date",
    "description_id" bigint,
    "id" bigint NOT NULL,
    "location_id" bigint,
    "position_id" bigint,
    "company_logo" character varying(255),
    "company_name" character varying(255)
);


ALTER TABLE "public"."work_experience" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."work_experience_seq"
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."work_experience_seq" OWNER TO "postgres";


ALTER TABLE ONLY "public"."document_rows" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."document_rows_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."n8n_chat_histories" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."n8n_chat_histories_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."achievement"
    ADD CONSTRAINT "achievement_description_id_key" UNIQUE ("description_id");



ALTER TABLE ONLY "public"."achievement"
    ADD CONSTRAINT "achievement_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_providers"
    ADD CONSTRAINT "agent_providers_pkey" PRIMARY KEY ("provider_name");



ALTER TABLE ONLY "public"."agent_sessions"
    ADD CONSTRAINT "agent_sessions_pkey" PRIMARY KEY ("session_id");



ALTER TABLE ONLY "public"."certification"
    ADD CONSTRAINT "certification_description_id_key" UNIQUE ("description_id");



ALTER TABLE ONLY "public"."certification"
    ADD CONSTRAINT "certification_name_id_key" UNIQUE ("name_id");



ALTER TABLE ONLY "public"."certification"
    ADD CONSTRAINT "certification_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."certification_technologies"
    ADD CONSTRAINT "certification_technologies_technologies_id_key" UNIQUE ("technologies_id");



ALTER TABLE ONLY "public"."client"
    ADD CONSTRAINT "client_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."coursework"
    ADD CONSTRAINT "coursework_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."coursework"
    ADD CONSTRAINT "coursework_title_id_key" UNIQUE ("title_id");



ALTER TABLE ONLY "public"."document_metadata"
    ADD CONSTRAINT "document_metadata_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."document_rows"
    ADD CONSTRAINT "document_rows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."documents_pg"
    ADD CONSTRAINT "documents_pg_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."education"
    ADD CONSTRAINT "education_degree_id_key" UNIQUE ("degree_id");



ALTER TABLE ONLY "public"."education"
    ADD CONSTRAINT "education_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."location"
    ADD CONSTRAINT "location_city_id_key" UNIQUE ("city_id");



ALTER TABLE ONLY "public"."location"
    ADD CONSTRAINT "location_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."n8n_chat_histories"
    ADD CONSTRAINT "n8n_chat_histories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project"
    ADD CONSTRAINT "project_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."responsibility"
    ADD CONSTRAINT "responsibility_description_id_key" UNIQUE ("description_id");



ALTER TABLE ONLY "public"."responsibility"
    ADD CONSTRAINT "responsibility_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."technology_topic_rate"
    ADD CONSTRAINT "technology_topic_rate_description_id_key" UNIQUE ("description_id");



ALTER TABLE ONLY "public"."technology_topic_rate"
    ADD CONSTRAINT "technology_topic_rate_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."translation_string"
    ADD CONSTRAINT "translation_string_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."work_experience"
    ADD CONSTRAINT "work_experience_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."document_rows"
    ADD CONSTRAINT "document_rows_dataset_id_fkey" FOREIGN KEY ("dataset_id") REFERENCES "public"."document_metadata"("id");



ALTER TABLE ONLY "public"."technology_topic_rate"
    ADD CONSTRAINT "fk1vc86alapekeoi8kq5fpade7h" FOREIGN KEY ("description_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."client_projects"
    ADD CONSTRAINT "fk3i9oo3vnblvtb4237agp3mlkn" FOREIGN KEY ("projects_id") REFERENCES "public"."project"("id");



ALTER TABLE ONLY "public"."coursework"
    ADD CONSTRAINT "fk3yw3oksgukcordbin3t4yo0ft" FOREIGN KEY ("title_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."achievement"
    ADD CONSTRAINT "fk5fdggtqm7t66jet2n1t50seij" FOREIGN KEY ("description_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."coursework"
    ADD CONSTRAINT "fk6701mikyufenvgi5g5v1i7jn3" FOREIGN KEY ("project_education_id") REFERENCES "public"."education"("id");



ALTER TABLE ONLY "public"."project_clients"
    ADD CONSTRAINT "fk6fv6a1ahxtve6qluamoae4t9q" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id");



ALTER TABLE ONLY "public"."certification_technologies"
    ADD CONSTRAINT "fk7tsw852jo6wdo5rshfk74swxy" FOREIGN KEY ("certification_id") REFERENCES "public"."certification"("id");



ALTER TABLE ONLY "public"."responsibility"
    ADD CONSTRAINT "fk7u3d9lli2doexxhis83i1b8u0" FOREIGN KEY ("description_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."achievement"
    ADD CONSTRAINT "fk8kd26v89a28y54hg74b8fbced" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id");



ALTER TABLE ONLY "public"."project_client"
    ADD CONSTRAINT "fk8xbtj75kf21i34pwvvn7bywkp" FOREIGN KEY ("client_id") REFERENCES "public"."client"("id");



ALTER TABLE ONLY "public"."project"
    ADD CONSTRAINT "fkap3eybb3uoguulhfwf6yi687d" FOREIGN KEY ("project_description_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."certification_technologies"
    ADD CONSTRAINT "fkaq5a76upi5525xbntthil878x" FOREIGN KEY ("technologies_id") REFERENCES "public"."technology_topic_rate"("id");



ALTER TABLE ONLY "public"."client_projects"
    ADD CONSTRAINT "fkbqu97yh0w6eipwh6xj5vm6vw0" FOREIGN KEY ("client_id") REFERENCES "public"."client"("id");



ALTER TABLE ONLY "public"."project"
    ADD CONSTRAINT "fkd16iubj36cco8q1ymjea4l5kk" FOREIGN KEY ("company_id") REFERENCES "public"."work_experience"("id");



ALTER TABLE ONLY "public"."location"
    ADD CONSTRAINT "fkf2r19cyr5bfms8aukcd3rlwgo" FOREIGN KEY ("city_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."project_clients"
    ADD CONSTRAINT "fkg0qy8e9yadjw4n1o0vch9yt0q" FOREIGN KEY ("clients_id") REFERENCES "public"."client"("id");



ALTER TABLE ONLY "public"."project_client"
    ADD CONSTRAINT "fkhfcsk6y3qootvig7kyh4thqyt" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id");



ALTER TABLE ONLY "public"."education"
    ADD CONSTRAINT "fkhi034ag0lgmn9jbcv4jhko0u1" FOREIGN KEY ("location_id") REFERENCES "public"."location"("id");



ALTER TABLE ONLY "public"."technology_topic_rate"
    ADD CONSTRAINT "fkjmm86mo7cgab85evlqtfacqif" FOREIGN KEY ("certification_id") REFERENCES "public"."certification"("id");



ALTER TABLE ONLY "public"."technology_topic_rate"
    ADD CONSTRAINT "fkjqshdaji9eyrh9p1qttmqu9b4" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id");



ALTER TABLE ONLY "public"."location"
    ADD CONSTRAINT "fkl62qnyw7yvdeu3em1360vck5o" FOREIGN KEY ("country_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."achievement"
    ADD CONSTRAINT "fkl91qnodv2kd7cqkunl6ckbdqm" FOREIGN KEY ("education_id") REFERENCES "public"."education"("id");



ALTER TABLE ONLY "public"."coursework"
    ADD CONSTRAINT "fknydduhcmi9smcncnx3bxsria1" FOREIGN KEY ("course_education_id") REFERENCES "public"."education"("id");



ALTER TABLE ONLY "public"."responsibility"
    ADD CONSTRAINT "fkox7apsn4qc4cto7qnv3humxon" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id");



ALTER TABLE ONLY "public"."work_experience"
    ADD CONSTRAINT "fkpnx0839d49e91gbingn2gls5" FOREIGN KEY ("location_id") REFERENCES "public"."location"("id");



ALTER TABLE ONLY "public"."work_experience"
    ADD CONSTRAINT "fkpysk3n9idw4shxo7qg53r4pd4" FOREIGN KEY ("position_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."education"
    ADD CONSTRAINT "fkrtwjk3957p5r8hhdq8ju6uhs1" FOREIGN KEY ("degree_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."certification"
    ADD CONSTRAINT "fktcb9dovn5fckppqcm2yglpei7" FOREIGN KEY ("description_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."work_experience"
    ADD CONSTRAINT "fkti2aj4llrm1i6np24b39dabhk" FOREIGN KEY ("description_id") REFERENCES "public"."translation_string"("id");



ALTER TABLE ONLY "public"."certification"
    ADD CONSTRAINT "fktjvmofqh3ain595usks5ppi0w" FOREIGN KEY ("name_id") REFERENCES "public"."translation_string"("id");





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";













































































































































































































































































































































































































































































































































GRANT ALL ON TABLE "public"."achievement" TO "anon";
GRANT ALL ON TABLE "public"."achievement" TO "authenticated";
GRANT ALL ON TABLE "public"."achievement" TO "service_role";



GRANT ALL ON SEQUENCE "public"."achievement_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."achievement_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."achievement_seq" TO "service_role";



GRANT ALL ON TABLE "public"."agent_providers" TO "anon";
GRANT ALL ON TABLE "public"."agent_providers" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_providers" TO "service_role";



GRANT ALL ON TABLE "public"."agent_sessions" TO "anon";
GRANT ALL ON TABLE "public"."agent_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."agent_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."certification" TO "anon";
GRANT ALL ON TABLE "public"."certification" TO "authenticated";
GRANT ALL ON TABLE "public"."certification" TO "service_role";



GRANT ALL ON SEQUENCE "public"."certification_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."certification_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."certification_seq" TO "service_role";



GRANT ALL ON TABLE "public"."certification_technologies" TO "anon";
GRANT ALL ON TABLE "public"."certification_technologies" TO "authenticated";
GRANT ALL ON TABLE "public"."certification_technologies" TO "service_role";



GRANT ALL ON TABLE "public"."client" TO "anon";
GRANT ALL ON TABLE "public"."client" TO "authenticated";
GRANT ALL ON TABLE "public"."client" TO "service_role";



GRANT ALL ON TABLE "public"."client_projects" TO "anon";
GRANT ALL ON TABLE "public"."client_projects" TO "authenticated";
GRANT ALL ON TABLE "public"."client_projects" TO "service_role";



GRANT ALL ON SEQUENCE "public"."client_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."client_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."client_seq" TO "service_role";



GRANT ALL ON TABLE "public"."coursework" TO "anon";
GRANT ALL ON TABLE "public"."coursework" TO "authenticated";
GRANT ALL ON TABLE "public"."coursework" TO "service_role";



GRANT ALL ON SEQUENCE "public"."coursework_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."coursework_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."coursework_seq" TO "service_role";



GRANT ALL ON TABLE "public"."document_metadata" TO "anon";
GRANT ALL ON TABLE "public"."document_metadata" TO "authenticated";
GRANT ALL ON TABLE "public"."document_metadata" TO "service_role";



GRANT ALL ON TABLE "public"."document_rows" TO "anon";
GRANT ALL ON TABLE "public"."document_rows" TO "authenticated";
GRANT ALL ON TABLE "public"."document_rows" TO "service_role";



GRANT ALL ON SEQUENCE "public"."document_rows_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."document_rows_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."document_rows_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."documents_pg" TO "anon";
GRANT ALL ON TABLE "public"."documents_pg" TO "authenticated";
GRANT ALL ON TABLE "public"."documents_pg" TO "service_role";



GRANT ALL ON TABLE "public"."education" TO "anon";
GRANT ALL ON TABLE "public"."education" TO "authenticated";
GRANT ALL ON TABLE "public"."education" TO "service_role";



GRANT ALL ON SEQUENCE "public"."education_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."education_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."education_seq" TO "service_role";



GRANT ALL ON TABLE "public"."location" TO "anon";
GRANT ALL ON TABLE "public"."location" TO "authenticated";
GRANT ALL ON TABLE "public"."location" TO "service_role";



GRANT ALL ON SEQUENCE "public"."location_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."location_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."location_seq" TO "service_role";



GRANT ALL ON TABLE "public"."n8n_chat_histories" TO "anon";
GRANT ALL ON TABLE "public"."n8n_chat_histories" TO "authenticated";
GRANT ALL ON TABLE "public"."n8n_chat_histories" TO "service_role";



GRANT ALL ON SEQUENCE "public"."n8n_chat_histories_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."n8n_chat_histories_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."n8n_chat_histories_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."positions_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."positions_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."positions_seq" TO "service_role";



GRANT ALL ON TABLE "public"."project" TO "anon";
GRANT ALL ON TABLE "public"."project" TO "authenticated";
GRANT ALL ON TABLE "public"."project" TO "service_role";



GRANT ALL ON TABLE "public"."project_client" TO "anon";
GRANT ALL ON TABLE "public"."project_client" TO "authenticated";
GRANT ALL ON TABLE "public"."project_client" TO "service_role";



GRANT ALL ON TABLE "public"."project_clients" TO "anon";
GRANT ALL ON TABLE "public"."project_clients" TO "authenticated";
GRANT ALL ON TABLE "public"."project_clients" TO "service_role";



GRANT ALL ON SEQUENCE "public"."project_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."project_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."project_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."projects_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."projects_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."projects_seq" TO "service_role";



GRANT ALL ON TABLE "public"."responsibility" TO "anon";
GRANT ALL ON TABLE "public"."responsibility" TO "authenticated";
GRANT ALL ON TABLE "public"."responsibility" TO "service_role";



GRANT ALL ON SEQUENCE "public"."responsibility_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."responsibility_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."responsibility_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."technologies_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."technologies_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."technologies_seq" TO "service_role";



GRANT ALL ON TABLE "public"."technology_topic_rate" TO "anon";
GRANT ALL ON TABLE "public"."technology_topic_rate" TO "authenticated";
GRANT ALL ON TABLE "public"."technology_topic_rate" TO "service_role";



GRANT ALL ON SEQUENCE "public"."technology_topic_rate_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."technology_topic_rate_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."technology_topic_rate_seq" TO "service_role";



GRANT ALL ON TABLE "public"."translation_string" TO "anon";
GRANT ALL ON TABLE "public"."translation_string" TO "authenticated";
GRANT ALL ON TABLE "public"."translation_string" TO "service_role";



GRANT ALL ON SEQUENCE "public"."translation_string_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."translation_string_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."translation_string_seq" TO "service_role";



GRANT ALL ON TABLE "public"."work_experience" TO "anon";
GRANT ALL ON TABLE "public"."work_experience" TO "authenticated";
GRANT ALL ON TABLE "public"."work_experience" TO "service_role";



GRANT ALL ON SEQUENCE "public"."work_experience_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."work_experience_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."work_experience_seq" TO "service_role";









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































