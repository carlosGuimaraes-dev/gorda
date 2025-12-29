-- Backend migrations (Postgres) - v1
-- Ordered migrations in a single file for now

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE role_enum AS ENUM ('manager', 'employee');
CREATE TYPE membership_status_enum AS ENUM ('active', 'invited', 'disabled');
CREATE TYPE invite_status_enum AS ENUM ('pending', 'accepted', 'expired');
CREATE TYPE task_status_enum AS ENUM ('scheduled', 'inProgress', 'completed', 'canceled');
CREATE TYPE finance_type_enum AS ENUM ('receivable', 'payable');
CREATE TYPE finance_status_enum AS ENUM ('pending', 'paid');
CREATE TYPE finance_kind_enum AS ENUM ('general', 'invoiceClient', 'payrollEmployee', 'expenseOutOfPocket');
CREATE TYPE currency_enum AS ENUM ('usd', 'eur');
CREATE TYPE payment_method_enum AS ENUM ('pix', 'card', 'cash');
CREATE TYPE notification_channel_enum AS ENUM ('whatsapp', 'sms', 'email');
CREATE TYPE notification_status_enum AS ENUM ('queued', 'sent', 'failed', 'delivered');
CREATE TYPE attachment_owner_enum AS ENUM ('finance_entry', 'task');

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE tenants (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  clerk_user_id text NOT NULL UNIQUE,
  email text,
  name text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE memberships (
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role role_enum NOT NULL,
  status membership_status_enum NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, user_id)
);

CREATE TABLE invites (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email text NOT NULL,
  role role_enum NOT NULL,
  status invite_status_enum NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL
);

CREATE TABLE devices (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform text NOT NULL,
  last_seen_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE clients (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name text NOT NULL,
  contact text,
  address text,
  property_details text,
  phone text,
  whatsapp_phone text,
  email text,
  access_notes text,
  preferred_schedule text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE employees (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name text NOT NULL,
  role_title text,
  team text,
  phone text,
  hourly_rate numeric,
  currency currency_enum,
  extra_earnings_description text,
  documents_description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE service_types (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  base_price numeric NOT NULL,
  currency currency_enum NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE tasks (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title text NOT NULL,
  date date NOT NULL,
  start_time timestamptz,
  end_time timestamptz,
  status task_status_enum NOT NULL,
  assigned_employee_id uuid REFERENCES employees(id),
  client_id uuid REFERENCES clients(id),
  client_name text,
  address text,
  notes text,
  service_type_id uuid REFERENCES service_types(id),
  check_in_time timestamptz,
  check_out_time timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE finance_entries (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title text NOT NULL,
  amount numeric NOT NULL,
  type finance_type_enum NOT NULL,
  due_date date NOT NULL,
  status finance_status_enum NOT NULL,
  method payment_method_enum,
  currency currency_enum NOT NULL,
  client_id uuid REFERENCES clients(id),
  client_name text,
  employee_id uuid REFERENCES employees(id),
  employee_name text,
  kind finance_kind_enum NOT NULL,
  is_disputed boolean NOT NULL DEFAULT false,
  dispute_reason text,
  receipt_attachment_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE attachments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  r2_key text NOT NULL,
  mime_type text NOT NULL,
  size integer NOT NULL,
  owner_type attachment_owner_enum NOT NULL,
  owner_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE conflict_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  entity text NOT NULL,
  entity_id uuid NOT NULL,
  fields text[] NOT NULL,
  summary text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  entity text NOT NULL,
  entity_id uuid NOT NULL,
  action text NOT NULL,
  summary text NOT NULL,
  actor text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  entity text NOT NULL,
  entity_id uuid NOT NULL,
  channel notification_channel_enum NOT NULL,
  status notification_status_enum NOT NULL,
  provider_message_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Update triggers
CREATE TRIGGER trg_clients_updated
BEFORE UPDATE ON clients
FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER trg_employees_updated
BEFORE UPDATE ON employees
FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER trg_service_types_updated
BEFORE UPDATE ON service_types
FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER trg_tasks_updated
BEFORE UPDATE ON tasks
FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER trg_finance_entries_updated
BEFORE UPDATE ON finance_entries
FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER trg_notifications_updated
BEFORE UPDATE ON notifications
FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

-- Common indexes
CREATE INDEX idx_clients_tenant_updated ON clients (tenant_id, updated_at DESC);
CREATE INDEX idx_employees_tenant_updated ON employees (tenant_id, updated_at DESC);
CREATE INDEX idx_service_types_tenant_updated ON service_types (tenant_id, updated_at DESC);
CREATE INDEX idx_tasks_tenant_updated ON tasks (tenant_id, updated_at DESC);
CREATE INDEX idx_finance_tenant_updated ON finance_entries (tenant_id, updated_at DESC);
CREATE INDEX idx_attachments_tenant_owner ON attachments (tenant_id, owner_type, owner_id);
CREATE INDEX idx_conflicts_tenant_created ON conflict_logs (tenant_id, created_at DESC);
CREATE INDEX idx_audit_tenant_created ON audit_logs (tenant_id, created_at DESC);
CREATE INDEX idx_notifications_tenant_created ON notifications (tenant_id, created_at DESC);
CREATE INDEX idx_invites_tenant_created ON invites (tenant_id, created_at DESC);

COMMIT;
