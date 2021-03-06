﻿-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/01.types-domains-tables-and-constraints/tables-and-constraints.sql --<--<--
DROP SCHEMA IF EXISTS finance CASCADE;
CREATE SCHEMA finance;

CREATE TABLE finance.verification_statuses
(
    verification_status_id                  smallint PRIMARY KEY,
    verification_status_name                national character varying(128) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

COMMENT ON TABLE finance.verification_statuses IS 
'Verification statuses are integer values used to represent the state of a transaction.
For example, a verification status of value "0" would mean that the transaction has not yet been verified.
A negative value indicates that the transaction was rejected, whereas a positive value means approved.

Remember:
1. Only approved transactions appear on ledgers and final reports.
2. Cash repository balance is maintained on the basis of LIFO principle. 

   This means that cash balance is affected (reduced) on your repository as soon as a credit transaction is posted,
   without the transaction being approved on the first place. If you reject the transaction, the cash balance then increases.
   This also means that the cash balance is not affected (increased) on your repository as soon as a debit transaction is posted.
   You will need to approve the transaction.

   It should however be noted that the cash repository balance might be less than the total cash shown on your balance sheet,
   if you have pending transactions to verify. You cannot perform EOD operation if you have pending verifications.
';


CREATE TABLE finance.frequencies
(
    frequency_id                            SERIAL PRIMARY KEY,
    frequency_code                          national character varying(12) NOT NULL,
    frequency_name                          national character varying(50) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);


CREATE UNIQUE INDEX frequencies_frequency_code_uix
ON finance.frequencies(UPPER(frequency_code))
WHERE NOT deleted;

CREATE UNIQUE INDEX frequencies_frequency_name_uix
ON finance.frequencies(UPPER(frequency_name))
WHERE NOT deleted;

CREATE TABLE finance.cash_repositories
(
    cash_repository_id                      SERIAL PRIMARY KEY,
    office_id                               integer NOT NULL REFERENCES core.offices,
    cash_repository_code                    national character varying(12) NOT NULL,
    cash_repository_name                    national character varying(50) NOT NULL,
    parent_cash_repository_id               integer NULL REFERENCES finance.cash_repositories,
    description                             national character varying(100) NULL,
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);


CREATE UNIQUE INDEX cash_repositories_cash_repository_code_uix
ON finance.cash_repositories(office_id, UPPER(cash_repository_code))
WHERE NOT deleted;

CREATE UNIQUE INDEX cash_repositories_cash_repository_name_uix
ON finance.cash_repositories(office_id, UPPER(cash_repository_name))
WHERE NOT deleted;


CREATE TABLE finance.fiscal_year
(
    fiscal_year_code                        national character varying(12) PRIMARY KEY,
    fiscal_year_name                        national character varying(50) NOT NULL,
    starts_from                             date NOT NULL,
    ends_on                                 date NOT NULL,
	eod_required							boolean NOT NULL DEFAULT(true),
	office_id								integer NOT NULL REFERENCES core.offices,
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX fiscal_year_fiscal_year_name_uix
ON finance.fiscal_year(UPPER(fiscal_year_name))
WHERE NOT deleted;

CREATE UNIQUE INDEX fiscal_year_starts_from_uix
ON finance.fiscal_year(starts_from)
WHERE NOT deleted;

CREATE UNIQUE INDEX fiscal_year_ends_on_uix
ON finance.fiscal_year(ends_on)
WHERE NOT deleted;



CREATE TABLE finance.account_masters
(
    account_master_id                       smallint PRIMARY KEY,
    account_master_code                     national character varying(3) NOT NULL,
    account_master_name                     national character varying(40) NOT NULL,
    normally_debit                          boolean NOT NULL CONSTRAINT account_masters_normally_debit_df DEFAULT(false),
    parent_account_master_id                smallint NULL REFERENCES finance.account_masters,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX account_master_code_uix
ON finance.account_masters(UPPER(account_master_code))
WHERE NOT deleted;

CREATE UNIQUE INDEX account_master_name_uix
ON finance.account_masters(UPPER(account_master_name))
WHERE NOT deleted;

CREATE INDEX account_master_parent_account_master_id_inx
ON finance.account_masters(parent_account_master_id)
WHERE NOT deleted;



CREATE TABLE finance.cost_centers
(
    cost_center_id                          SERIAL PRIMARY KEY,
    cost_center_code                        national character varying(24) NOT NULL,
    cost_center_name                        national character varying(50) NOT NULL,
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX cost_centers_cost_center_code_uix
ON finance.cost_centers(UPPER(cost_center_code))
WHERE NOT deleted;

CREATE UNIQUE INDEX cost_centers_cost_center_name_uix
ON finance.cost_centers(UPPER(cost_center_name))
WHERE NOT deleted;


CREATE TABLE finance.frequency_setups
(
    frequency_setup_id                      SERIAL PRIMARY KEY,
    fiscal_year_code                        national character varying(12) NOT NULL REFERENCES finance.fiscal_year(fiscal_year_code),
    frequency_setup_code                    national character varying(12) NOT NULL,
    value_date                              date NOT NULL UNIQUE,
    frequency_id                            integer NOT NULL REFERENCES finance.frequencies,
	office_id								integer NOT NULL REFERENCES core.offices,
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX frequency_setups_frequency_setup_code_uix
ON finance.frequency_setups(UPPER(frequency_setup_code))
WHERE NOT deleted;



CREATE TABLE finance.accounts
(
    account_id                              BIGSERIAL PRIMARY KEY,
    account_master_id                       smallint NOT NULL REFERENCES finance.account_masters,
    account_number                          national character varying(12) NOT NULL,
    external_code                           national character varying(12) NULL CONSTRAINT accounts_external_code_df DEFAULT(''),
    currency_code                           national character varying(12) NOT NULL REFERENCES core.currencies,
    account_name                            national character varying(100) NOT NULL,
    description                             national character varying(200) NULL,
    confidential                            boolean NOT NULL CONSTRAINT accounts_confidential_df DEFAULT(false),
    is_transaction_node                     boolean NOT NULL --Non transaction nodes cannot be used in transaction.
                                            CONSTRAINT accounts_is_transaction_node_df DEFAULT(true),
    sys_type                                boolean NOT NULL CONSTRAINT accounts_sys_type_df DEFAULT(false),
    parent_account_id                       bigint NULL REFERENCES finance.accounts,
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);


CREATE UNIQUE INDEX accounts_account_number_uix
ON finance.accounts(UPPER(account_number))
WHERE NOT deleted;

CREATE UNIQUE INDEX accounts_name_uix
ON finance.accounts(UPPER(account_name))
WHERE NOT deleted;


CREATE TABLE finance.cash_flow_headings
(
    cash_flow_heading_id                    integer NOT NULL PRIMARY KEY,
    cash_flow_heading_code                  national character varying(12) NOT NULL,
    cash_flow_heading_name                  national character varying(100) NOT NULL,
    cash_flow_heading_type                  character(1) NOT NULL
                                            CONSTRAINT cash_flow_heading_cash_flow_heading_type_chk CHECK(cash_flow_heading_type IN('O', 'I', 'F')),
    is_debit                                boolean NOT NULL CONSTRAINT cash_flow_headings_is_debit_df
                                            DEFAULT(false),
    is_sales                                boolean NOT NULL CONSTRAINT cash_flow_headings_is_sales_df
                                            DEFAULT(false),
    is_purchase                             boolean NOT NULL CONSTRAINT cash_flow_headings_is_purchase_df
                                            DEFAULT(false),
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX cash_flow_headings_cash_flow_heading_code_uix
ON finance.cash_flow_headings(UPPER(cash_flow_heading_code))
WHERE NOT deleted;

CREATE UNIQUE INDEX cash_flow_headings_cash_flow_heading_name_uix
ON finance.cash_flow_headings(UPPER(cash_flow_heading_code))
WHERE NOT deleted;



CREATE TABLE finance.bank_accounts
(
	bank_account_id							SERIAL PRIMARY KEY,
    account_id                              bigint REFERENCES finance.accounts,                                            
    maintained_by_user_id                   integer NOT NULL REFERENCES account.users,
	is_merchant_account 					boolean NOT NULL DEFAULT(false),
    office_id                               integer NOT NULL REFERENCES core.offices,
    bank_name                               national character varying(128) NOT NULL,
    bank_branch                             national character varying(128) NOT NULL,
    bank_contact_number                     national character varying(128) NULL,
    bank_account_number                     national character varying(128) NULL,
    bank_account_type                       national character varying(128) NULL,
    street                                  national character varying(50) NULL,
    city                                    national character varying(50) NULL,
    state                                   national character varying(50) NULL,
    country                                 national character varying(50) NULL,
    phone                                   national character varying(50) NULL,
    fax                                     national character varying(50) NULL,
    cell                                    national character varying(50) NULL,
    relationship_officer_name               national character varying(128) NULL,
    relationship_officer_contact_number     national character varying(128) NULL,
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE TABLE finance.transaction_types
(
    transaction_type_id                     smallint PRIMARY KEY,
    transaction_type_code                   national character varying(4),
    transaction_type_name                   national character varying(100),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX transaction_types_transaction_type_code_uix
ON finance.transaction_types(UPPER(transaction_type_code))
WHERE NOT deleted;

CREATE UNIQUE INDEX transaction_types_transaction_type_name_uix
ON finance.transaction_types(UPPER(transaction_type_name))
WHERE NOT deleted;

INSERT INTO finance.transaction_types
SELECT 1, 'Any', 'Any (Debit or Credit)' UNION ALL
SELECT 2, 'Dr', 'Debit' UNION ALL
SELECT 3, 'Cr', 'Credit';



CREATE TABLE finance.cash_flow_setup
(
    cash_flow_setup_id                      SERIAL PRIMARY KEY,
    cash_flow_heading_id                    integer NOT NULL REFERENCES finance.cash_flow_headings,
    account_master_id                       smallint NOT NULL REFERENCES finance.account_masters,
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE INDEX cash_flow_setup_cash_flow_heading_id_inx
ON finance.cash_flow_setup(cash_flow_heading_id)
WHERE NOT deleted;

CREATE INDEX cash_flow_setup_account_master_id_inx
ON finance.cash_flow_setup(account_master_id)
WHERE NOT deleted;



CREATE TABLE finance.transaction_master
(
    transaction_master_id                   BIGSERIAL PRIMARY KEY,
    transaction_counter                     integer NOT NULL, --Sequence of transactions of a date
    transaction_code                        national character varying(50) NOT NULL,
    book                                    national character varying(50) NOT NULL, --Transaction book. Ex. Sales, Purchase, Journal
    value_date                              date NOT NULL,
    book_date                              	date NOT NULL,
    transaction_ts                          TIMESTAMP WITH TIME ZONE NOT NULL   
                                            DEFAULT(NOW()),
    login_id                                bigint NOT NULL REFERENCES account.logins,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    cost_center_id                          integer REFERENCES finance.cost_centers,
    reference_number                        national character varying(24),
    statement_reference                     text,
    last_verified_on                        TIMESTAMP WITH TIME ZONE, 
    verified_by_user_id                     integer REFERENCES account.users,
    verification_status_id                  smallint NOT NULL REFERENCES finance.verification_statuses   
                                            DEFAULT(0/*Awaiting verification*/),
    verification_reason                     national character varying(128) NOT NULL DEFAULT(''),
	cascading_tran_id 						bigint REFERENCES finance.transaction_master,
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX transaction_master_transaction_code_uix
ON finance.transaction_master(UPPER(transaction_code))
WHERE NOT deleted;

CREATE INDEX transaction_master_cascading_tran_id_inx
ON finance.transaction_master(cascading_tran_id)
WHERE NOT deleted;

CREATE TABLE finance.transaction_documents
(
	document_id								BIGSERIAL PRIMARY KEY,
	transaction_master_id					bigint NOT NULL REFERENCES finance.transaction_master,
	original_file_name						national character varying(500) NOT NULL,
	file_extension							national character varying(50),
	file_path								national character varying(2000) NOT NULL,
	memo									national character varying(2000),
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);


CREATE TABLE finance.transaction_details
(
    transaction_detail_id                   BIGSERIAL PRIMARY KEY,
    transaction_master_id                   bigint NOT NULL REFERENCES finance.transaction_master,
    value_date                              date NOT NULL,
    book_date                              	date NOT NULL,
    tran_type                               national character varying(4) NOT NULL CHECK(tran_type IN ('Dr', 'Cr')),
    account_id                              bigint NOT NULL REFERENCES finance.accounts,
    statement_reference                     text,
    cash_repository_id                      integer REFERENCES finance.cash_repositories,
    currency_code                           national character varying(12) NOT NULL REFERENCES core.currencies,
    amount_in_currency                      money_strict NOT NULL,
    local_currency_code                     national character varying(12) NOT NULL REFERENCES core.currencies,
    er                                      decimal_strict NOT NULL,
    amount_in_local_currency                money_strict NOT NULL,  
    office_id                               integer NOT NULL REFERENCES core.offices,
    audit_user_id                           integer NULL REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW())
);


CREATE TABLE finance.card_types
(
	card_type_id                    		integer PRIMARY KEY,
	card_type_code                  		national character varying(12) NOT NULL,
	card_type_name                  		national character varying(100) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX card_types_card_type_code_uix
ON finance.card_types(UPPER(card_type_code))
WHERE NOT deleted;

CREATE UNIQUE INDEX card_types_card_type_name_uix
ON finance.card_types(UPPER(card_type_name))
WHERE NOT deleted;

CREATE TABLE finance.payment_cards
(
	payment_card_id                     	SERIAL PRIMARY KEY,
	payment_card_code                   	national character varying(12) NOT NULL,
	payment_card_name                   	national character varying(100) NOT NULL,
	card_type_id                        	integer NOT NULL REFERENCES finance.card_types,            
	audit_user_id                       	integer NULL REFERENCES account.users,            
	audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)            
);

CREATE UNIQUE INDEX payment_cards_payment_card_code_uix
ON finance.payment_cards(UPPER(payment_card_code))
WHERE NOT deleted;

CREATE UNIQUE INDEX payment_cards_payment_card_name_uix
ON finance.payment_cards(UPPER(payment_card_name))
WHERE NOT deleted;    


CREATE TABLE finance.merchant_fee_setup
(
	merchant_fee_setup_id               	SERIAL PRIMARY KEY,
	merchant_account_id                 	bigint NOT NULL REFERENCES finance.bank_accounts,
	payment_card_id                     	integer NOT NULL REFERENCES finance.payment_cards,
	rate                                	public.decimal_strict NOT NULL,
	customer_pays_fee                   	boolean NOT NULL DEFAULT(false),
	account_id                          	bigint NOT NULL REFERENCES finance.accounts,
	statement_reference                 	national character varying(128) NOT NULL DEFAULT(''),
	audit_user_id                       	integer NULL REFERENCES account.users,            
	audit_ts                            	TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)            
);

CREATE UNIQUE INDEX merchant_fee_setup_merchant_account_id_payment_card_id_uix
ON finance.merchant_fee_setup(merchant_account_id, payment_card_id)
WHERE NOT deleted;


CREATE TABLE finance.exchange_rates
(
    exchange_rate_id                        BIGSERIAL PRIMARY KEY,
    updated_on                              TIMESTAMP WITH TIME ZONE NOT NULL   
                                            CONSTRAINT exchange_rates_updated_on_df 
                                            DEFAULT(NOW()),
    office_id                               integer NOT NULL REFERENCES core.offices,
    status                                  BOOLEAN NOT NULL   
                                            CONSTRAINT exchange_rates_status_df 
                                            DEFAULT(true)
);

CREATE TABLE finance.exchange_rate_details
(
    exchange_rate_detail_id                 BIGSERIAL PRIMARY KEY,
    exchange_rate_id                        bigint NOT NULL REFERENCES finance.exchange_rates,
    local_currency_code                     national character varying(12) NOT NULL REFERENCES core.currencies,
    foreign_currency_code                   national character varying(12) NOT NULL REFERENCES core.currencies,
    unit                                    integer_strict NOT NULL,
    exchange_rate                           decimal_strict NOT NULL
);


DROP TYPE IF EXISTS finance.period CASCADE;

CREATE TYPE finance.period AS
(
    period_name                     text,
    date_from                       date,
    date_to                         date
);

CREATE TABLE finance.journal_verification_policy
(
    journal_verification_policy_id          SERIAL PRIMARY KEY,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    can_verify                              boolean NOT NULL DEFAULT(false),
    verification_limit                      public.money_strict2 NOT NULL DEFAULT(0),
    can_self_verify                         boolean NOT NULL DEFAULT(false),
    self_verification_limit                 money_strict2 NOT NULL DEFAULT(0),
    effective_from                          date NOT NULL,
    ends_on                                 date NOT NULL,
    is_active                               boolean NOT NULL,
	audit_user_id                       	integer NULL REFERENCES account.users,            
	audit_ts                            	TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)            
);


CREATE TABLE finance.auto_verification_policy
(
    auto_verification_policy_id             SERIAL PRIMARY KEY,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    verification_limit                      public.money_strict2 NOT NULL DEFAULT(0),
    effective_from                          date NOT NULL,
    ends_on                                 date NOT NULL,
    is_active                               boolean NOT NULL,
	audit_user_id                       	integer NULL REFERENCES account.users,            
	audit_ts                            	TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)                                            
);

CREATE TABLE finance.tax_setups
(
	tax_setup_id							SERIAL PRIMARY KEY,
	office_id								integer NOT NULL REFERENCES core.offices,
	income_tax_rate							public.decimal_strict NOT NULL,
	audit_user_id                       	integer NULL REFERENCES account.users,            
	audit_ts                            	TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)                                            
);

CREATE UNIQUE INDEX tax_setup_office_id_uix
ON finance.tax_setups(office_id)
WHERE NOT finance.tax_setups.deleted;


CREATE TABLE finance.routines
(
    routine_id                              SERIAL NOT NULL PRIMARY KEY,
    "order"                                 integer NOT NULL,
    routine_code                            national character varying(12) NOT NULL,
    routine_name                            regproc NOT NULL UNIQUE,
    status                                  boolean NOT NULL CONSTRAINT routines_status_df DEFAULT(true)
);

CREATE UNIQUE INDEX routines_routine_code_uix
ON finance.routines(LOWER(routine_code));

CREATE TABLE finance.day_operation
(
    day_id                                  BIGSERIAL PRIMARY KEY,
    office_id                               integer NOT NULL REFERENCES core.offices,
    value_date                              date NOT NULL,
    started_on                              TIMESTAMP WITH TIME ZONE NOT NULL,
    started_by                              integer NOT NULL REFERENCES account.users,    
    completed_on                            TIMESTAMP WITH TIME ZONE NULL,
    completed_by                            integer NULL REFERENCES account.users,
    completed                               boolean NOT NULL 
                                            CONSTRAINT day_operation_completed_df DEFAULT(false)
                                            CONSTRAINT day_operation_completed_chk 
                                            CHECK
                                            (
                                                (completed OR completed_on IS NOT NULL)
                                                OR
                                                (NOT completed OR completed_on IS NULL)
                                            )
);


CREATE UNIQUE INDEX day_operation_value_date_uix
ON finance.day_operation(value_date);

CREATE INDEX day_operation_completed_on_inx
ON finance.day_operation(completed_on);

CREATE TABLE finance.day_operation_routines
(
    day_operation_routine_id                BIGSERIAL NOT NULL PRIMARY KEY,
    day_id                                  bigint NOT NULL REFERENCES finance.day_operation,
    routine_id                              integer NOT NULL REFERENCES finance.routines,
    started_on                              TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_on                            TIMESTAMP WITH TIME ZONE NULL
);

CREATE INDEX day_operation_routines_started_on_inx
ON finance.day_operation_routines(started_on);

CREATE INDEX day_operation_routines_completed_on_inx
ON finance.day_operation_routines(completed_on);



-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.auto_verify.sql --<--<--
DROP FUNCTION IF EXISTS finance.auto_verify
(
    _tran_id        bigint,
    _office_id      integer
) CASCADE;

CREATE FUNCTION finance.auto_verify
(
    _tran_id        bigint,
    _office_id      integer
)
RETURNS VOID
VOLATILE
AS
$$
    DECLARE _transaction_master_id          bigint;
    DECLARE _transaction_posted_by          integer;
    DECLARE _verifier                       integer;
    DECLARE _status                         integer = 1;
    DECLARE _reason                         national character varying(128) = 'Automatically verified';
    DECLARE _rejected                       smallint=-3;
    DECLARE _closed                         smallint=-2;
    DECLARE _withdrawn                      smallint=-1;
    DECLARE _unapproved                     smallint = 0;
    DECLARE _auto_approved                  smallint = 1;
    DECLARE _approved                       smallint=2;
    DECLARE _book                           text;
    DECLARE _verification_limit             public.money_strict2;
    DECLARE _posted_amount                  public.money_strict2;
    DECLARE _has_policy                     boolean=false;
    DECLARE _voucher_date                   date;
BEGIN
    _transaction_master_id := $1;

    SELECT
        finance.transaction_master.book,
        finance.transaction_master.value_date,
        finance.transaction_master.user_id
    INTO
        _book,
        _voucher_date,
        _transaction_posted_by  
    FROM finance.transaction_master
    WHERE finance.transaction_master.transaction_master_id=_transaction_master_id
	AND NOT finance.transaction_master.deleted;
    
    SELECT
        SUM(amount_in_local_currency)
    INTO
        _posted_amount
    FROM
        finance.transaction_details
    WHERE finance.transaction_details.transaction_master_id = _transaction_master_id
    AND finance.transaction_details.tran_type='Cr';


    SELECT
        true,
        verification_limit
    INTO
        _has_policy,
        _verification_limit
    FROM finance.auto_verification_policy
    WHERE finance.auto_verification_policy.user_id=_transaction_posted_by
    AND finance.auto_verification_policy.office_id = _office_id
    AND finance.auto_verification_policy.is_active=true
    AND now() >= effective_from
    AND now() <= ends_on
	AND NOT finance.auto_verification_policy.deleted;

    IF(_has_policy=true) THEN
        UPDATE finance.transaction_master
        SET 
            last_verified_on = now(),
            verified_by_user_id=_verifier,
            verification_status_id=_status,
            verification_reason=_reason
        WHERE
            finance.transaction_master.transaction_master_id=_transaction_master_id
        OR
            finance.transaction_master.cascading_tran_id=_transaction_master_id
        OR
        finance.transaction_master.transaction_master_id = 
        (
            SELECT cascading_tran_id
            FROM finance.transaction_master
            WHERE finance.transaction_master.transaction_master_id=_transaction_master_id 
        );
    ELSE
        RAISE NOTICE 'No auto verification policy found for this user.';
    END IF;
    RETURN;
END
$$
LANGUAGE plpgsql;

--SELECT * FROM finance.auto_verify(1, 1);

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.can_post_transaction.sql --<--<--
DROP FUNCTION IF EXISTS finance.can_post_transaction(_login_id bigint, _user_id integer, _office_id integer, transaction_book text, _value_date date);
DROP FUNCTION IF EXISTS finance.can_post_transaction(_login_id bigint, _user_id integer, _office_id integer, transaction_book text, _value_date timestamp);

CREATE FUNCTION finance.can_post_transaction(_login_id bigint, _user_id integer, _office_id integer, transaction_book text, _value_date date)
RETURNS bool
AS
$$
    DECLARE _eod_required                       boolean := finance.eod_required(_office_id);
    DECLARE _fiscal_year_start_date             date    := finance.get_fiscal_year_start_date(_office_id);
    DECLARE _fiscal_year_end_date               date    := finance.get_fiscal_year_end_date(_office_id);
BEGIN
    IF(account.is_valid_login_id(_login_id) = false) THEN
        RAISE EXCEPTION 'Invalid LoginId.'
        USING ERRCODE='P3101';
    END IF; 

    IF(core.is_valid_office_id(_office_id) = false) THEN
        RAISE EXCEPTION 'Invalid OfficeId.'
        USING ERRCODE='P3010';
    END IF;

    IF(finance.is_transaction_restricted(_office_id)) THEN
        RAISE EXCEPTION 'This establishment does not allow transaction posting.'
        USING ERRCODE='P5100';
    END IF;
    
    IF(_eod_required) THEN
        IF(finance.is_restricted_mode()) THEN
            RAISE EXCEPTION 'Cannot post transaction during restricted transaction mode.'
            USING ERRCODE='P5101';
        END IF;

        IF(_value_date < finance.get_value_date(_office_id)) THEN
            RAISE EXCEPTION 'Past dated transactions are not allowed.'
            USING ERRCODE='P5010';
        END IF;
    END IF;

    IF(_value_date < _fiscal_year_start_date) THEN
        RAISE EXCEPTION 'You cannot post transactions before the current fiscal year start date.'
        USING ERRCODE='P5010';
    END IF;

    IF(_value_date > _fiscal_year_end_date) THEN
        RAISE EXCEPTION 'You cannot post transactions after the current fiscal year end date.'
        USING ERRCODE='P5010';
    END IF;
    
    IF NOT EXISTS 
    (
        SELECT *
        FROM account.users
        INNER JOIN account.roles
        ON account.users.role_id = account.roles.role_id
        AND user_id = _user_id
    ) THEN
        RAISE EXCEPTION 'Access is denied. You are not authorized to post this transaction.'
        USING ERRCODE='P9010';        
    END IF;

    RETURN true;
END
$$
LANGUAGE plpgsql;

CREATE FUNCTION finance.can_post_transaction(_login_id bigint, _user_id integer, _office_id integer, transaction_book text, _value_date timestamp)
RETURNS bool
AS
$$
BEGIN
    RETURN finance.can_post_transaction(_login_id, _user_id, _office_id, transaction_book, _value_date::date);
END
$$
LANGUAGE plpgsql;

--SELECT finance.can_post_transaction(1, 1, 1, 'Sales', '1-1-2020');

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.create_routine.sql --<--<--
DROP FUNCTION IF EXISTS finance.create_routine(_routine_code national character varying(12), _routine regproc, _order integer);

CREATE FUNCTION finance.create_routine(_routine_code national character varying(12), _routine regproc, _order integer)
RETURNS void
AS
$$
BEGIN
    IF NOT EXISTS(SELECT * FROM finance.routines WHERE routine_code=_routine_code) THEN
        INSERT INTO finance.routines(routine_code, routine_name, "order")
        SELECT $1, $2, $3;
        RETURN;
    END IF;

    UPDATE finance.routines
    SET
        routine_name = _routine,
        "order" = _order
    WHERE routine_code=_routine_code;
    RETURN;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.date_functions.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_date(_office_id integer);

CREATE FUNCTION finance.get_date(_office_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN finance.get_value_date($1);
END
$$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS finance.get_month_end_date(_office_id integer);

CREATE FUNCTION finance.get_month_end_date(_office_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN MIN(value_date) 
    FROM finance.frequency_setups
    WHERE value_date >= finance.get_value_date($1)
	AND NOT finance.frequency_setups.deleted;
END
$$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS finance.get_month_start_date(_office_id integer);

CREATE FUNCTION finance.get_month_start_date(_office_id integer)
RETURNS date
AS
$$
    DECLARE _date               date;
BEGIN
    SELECT MAX(value_date) + 1
    INTO _date
    FROM finance.frequency_setups
    WHERE value_date < 
    (
        SELECT MIN(value_date)
        FROM finance.frequency_setups
        WHERE value_date >= finance.get_value_date($1)
		AND NOT finance.frequency_setups.deleted
    )
	AND NOT finance.frequency_setups.deleted;

    IF(_date IS NULL) THEN
        SELECT starts_from 
        INTO _date
        FROM finance.fiscal_year
		WHERE NOT finance.fiscal_year.deleted;
    END IF;

    RETURN _date;
END
$$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS finance.get_quarter_end_date(_office_id integer);

CREATE FUNCTION finance.get_quarter_end_date(_office_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN MIN(value_date) 
    FROM finance.frequency_setups
    WHERE value_date >= finance.get_value_date($1)
    AND frequency_id > 2
	AND NOT finance.frequency_setups.deleted;
END
$$
LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS finance.get_quarter_start_date(_office_id integer);

CREATE FUNCTION finance.get_quarter_start_date(_office_id integer)
RETURNS date
AS
$$
    DECLARE _date               date;
BEGIN
    SELECT MAX(value_date) + 1
    INTO _date
    FROM finance.frequency_setups
    WHERE value_date < 
    (
        SELECT MIN(value_date)
        FROM finance.frequency_setups
        WHERE value_date >= finance.get_value_date($1)
		AND NOT finance.frequency_setups.deleted
    )
    AND frequency_id > 2
	AND NOT finance.frequency_setups.deleted;

    IF(_date IS NULL) THEN
        SELECT starts_from 
        INTO _date
        FROM finance.fiscal_year
		WHERE NOT finance.fiscal_year.deleted;
    END IF;

    RETURN _date;
END
$$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS finance.get_fiscal_half_end_date(_office_id integer);

CREATE FUNCTION finance.get_fiscal_half_end_date(_office_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN MIN(value_date) 
    FROM finance.frequency_setups
    WHERE value_date >= finance.get_value_date($1)
    AND frequency_id > 3
	AND NOT finance.frequency_setups.deleted;
END
$$
LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS finance.get_fiscal_half_start_date(_office_id integer);

CREATE FUNCTION finance.get_fiscal_half_start_date(_office_id integer)
RETURNS date
AS
$$
    DECLARE _date               date;
BEGIN
    SELECT MAX(value_date) + 1
    INTO _date
    FROM finance.frequency_setups
    WHERE value_date < 
    (
        SELECT MIN(value_date)
        FROM finance.frequency_setups
        WHERE value_date >= finance.get_value_date($1)
		AND NOT finance.frequency_setups.deleted
    )
    AND frequency_id > 3
	AND NOT finance.frequency_setups.deleted;

    IF(_date IS NULL) THEN
        SELECT starts_from 
        INTO _date
        FROM finance.fiscal_year
		WHERE NOT finance.fiscal_year.deleted;
    END IF;

    RETURN _date;
END
$$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS finance.get_fiscal_year_end_date(_office_id integer);

CREATE FUNCTION finance.get_fiscal_year_end_date(_office_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN MIN(value_date) 
    FROM finance.frequency_setups
    WHERE value_date >= finance.get_value_date($1)
    AND frequency_id > 4
	AND NOT finance.frequency_setups.deleted;
END
$$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS finance.get_fiscal_year_start_date(_office_id integer);

CREATE FUNCTION finance.get_fiscal_year_start_date(_office_id integer)
RETURNS date
AS
$$
    DECLARE _date               date;
BEGIN

    SELECT starts_from 
    INTO _date
    FROM finance.fiscal_year
	WHERE NOT finance.fiscal_year.deleted;

    RETURN _date;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.eod_required.sql --<--<--
DROP FUNCTION IF EXISTS finance.eod_required(_office_id integer);

CREATE FUNCTION finance.eod_required(_office_id integer)
RETURNS boolean
AS
$$
BEGIN
    RETURN finance.fiscal_year.eod_required
    FROM finance.fiscal_year
    WHERE finance.fiscal_year.office_id = _office_id;
END
$$
LANGUAGE plpgsql;

--SELECT finance.eod_required(1);

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_account_id_by_account_name.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_account_id_by_account_name(text);

CREATE FUNCTION finance.get_account_id_by_account_name(text)
RETURNS bigint
STABLE
AS
$$
BEGIN
    RETURN
		account_id
    FROM finance.accounts
    WHERE finance.accounts.account_name=$1
	AND NOT finance.accounts.deleted;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_account_id_by_account_number.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_account_id_by_account_number(text);

CREATE FUNCTION finance.get_account_id_by_account_number(text)
RETURNS bigint
STABLE
AS
$$
BEGIN
    RETURN
		account_id
    FROM finance.accounts
    WHERE finance.accounts.account_number=$1
	AND NOT finance.accounts.deleted;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_account_ids.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_account_ids(root_account_id bigint);

CREATE FUNCTION finance.get_account_ids(root_account_id bigint)
RETURNS SETOF bigint
STABLE
AS
$$
BEGIN
    RETURN QUERY 
    (
        WITH RECURSIVE account_cte(account_id, path) AS (
         SELECT
            tn.account_id,  tn.account_id::TEXT AS path
            FROM finance.accounts AS tn 
			WHERE tn.account_id =$1
			AND NOT tn.deleted
        UNION ALL
         SELECT
            c.account_id, (p.path || '->' || c.account_id::TEXT)
            FROM account_cte AS p, finance.accounts AS c WHERE parent_account_id = p.account_id
        )

        SELECT account_id FROM account_cte
    );
END
$$LANGUAGE plpgsql;



-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_account_master_id_by_account_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_account_master_id_by_account_id(bigint) CASCADE;

CREATE FUNCTION finance.get_account_master_id_by_account_id(bigint)
RETURNS integer
STABLE
AS
$$
BEGIN
    RETURN finance.accounts.account_master_id
    FROM finance.accounts
    WHERE finance.accounts.account_id= $1
	AND NOT finance.accounts.deleted;
END
$$
LANGUAGE plpgsql;

ALTER TABLE finance.bank_accounts
ADD CONSTRAINT bank_accounts_account_id_chk 
CHECK
(
    finance.get_account_master_id_by_account_id(account_id) = '10102'
);

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_account_master_id_by_account_master_code.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_account_master_id_by_account_master_code(text);

CREATE FUNCTION finance.get_account_master_id_by_account_master_code(_account_master_code text)
RETURNS integer
STABLE
AS
$$
BEGIN
    RETURN finance.account_masters.account_master_id
    FROM finance.account_masters
    WHERE finance.account_masters.account_master_code = $1
	AND NOT finance.account_masters.deleted;
END
$$
LANGUAGE plpgsql;



-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_account_name.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_account_name_by_account_id(bigint);

CREATE FUNCTION finance.get_account_name_by_account_id(_account_id bigint)
RETURNS text
STABLE
AS
$$
BEGIN
    RETURN account_name
    FROM finance.accounts
    WHERE finance.accounts.account_id=$1
	AND NOT finance.accounts.deleted;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_account_statement.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_account_statement
(
    _value_date_from        date,
    _value_date_to          date,
    _user_id                integer,
    _account_id             bigint,
    _office_id              integer
);

CREATE FUNCTION finance.get_account_statement
(
    _value_date_from        date,
    _value_date_to          date,
    _user_id                integer,
    _account_id             bigint,
    _office_id              integer
)
RETURNS TABLE
(
    id                      integer,
    value_date              date,
    book_date               date,
    tran_code               text,
    reference_number        text,
    statement_reference     text,
    debit                   decimal(24, 4),
    credit                  decimal(24, 4),
    balance                 decimal(24, 4),
    office                  text,
    book                    text,
    account_id              integer,
    account_number          text,
    account                 text,
    posted_on               TIMESTAMP WITH TIME ZONE,
    posted_by               text,
    approved_by             text,
    verification_status     integer,
    flag_bg                 text,
    flag_fg                 text
)
AS
$$
    DECLARE _normally_debit boolean;
BEGIN

    _normally_debit             := finance.is_normally_debit(_account_id);

    DROP TABLE IF EXISTS temp_account_statement;
    CREATE TEMPORARY TABLE temp_account_statement
    (
        id                      SERIAL,
        value_date              date,
        book_date               date,
        tran_code               text,
        reference_number        text,
        statement_reference     text,
        debit                   decimal(24, 4),
        credit                  decimal(24, 4),
        balance                 decimal(24, 4),
        office                  text,
        book                    text,
        account_id              integer,
        account_number          text,
        account                 text,
        posted_on               TIMESTAMP WITH TIME ZONE,
        posted_by               text,
        approved_by             text,
        verification_status     integer,
        flag_bg                 text,
        flag_fg                 text
    ) ON COMMIT DROP;


    INSERT INTO temp_account_statement(value_date, book_date, tran_code, reference_number, statement_reference, debit, credit, office, book, account_id, posted_on, posted_by, approved_by, verification_status)
    SELECT
        _value_date_from,
        _value_date_from,
        NULL,
        NULL,
        'Opening Balance',
        NULL,
        SUM
        (
            CASE finance.transaction_details.tran_type
            WHEN 'Cr' THEN amount_in_local_currency
            ELSE amount_in_local_currency * -1 
            END            
        ) as credit,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    FROM finance.transaction_master
    INNER JOIN finance.transaction_details
    ON finance.transaction_master.transaction_master_id = finance.transaction_details.transaction_master_id
    WHERE finance.transaction_master.verification_status_id > 0
    AND finance.transaction_master.value_date < _value_date_from
    AND finance.transaction_master.office_id IN (SELECT * FROM core.get_office_ids(_office_id)) 
    AND finance.transaction_details.account_id IN (SELECT * FROM finance.get_account_ids(_account_id))
    AND NOT finance.transaction_master.deleted;

    DELETE FROM temp_account_statement
    WHERE COALESCE(temp_account_statement.debit, 0) = 0
    AND COALESCE(temp_account_statement.credit, 0) = 0;
    

    UPDATE temp_account_statement SET 
    debit = temp_account_statement.credit * -1,
    credit = 0
    WHERE temp_account_statement.credit < 0;
    

    INSERT INTO temp_account_statement(value_date, book_date, tran_code, reference_number, statement_reference, debit, credit, office, book, account_id, posted_on, posted_by, approved_by, verification_status)
    SELECT
        finance.transaction_master.value_date,
        finance.transaction_master.book_date,
        finance.transaction_master. transaction_code,
        finance.transaction_master.reference_number::text,
        finance.transaction_details.statement_reference,
        CASE finance.transaction_details.tran_type
        WHEN 'Dr' THEN amount_in_local_currency
        ELSE NULL END,
        CASE finance.transaction_details.tran_type
        WHEN 'Cr' THEN amount_in_local_currency
        ELSE NULL END,
        core.get_office_name_by_office_id(finance.transaction_master.office_id),
        finance.transaction_master.book,
        finance.transaction_details.account_id,
        finance.transaction_master.transaction_ts,
        account.get_name_by_user_id(finance.transaction_master.user_id),
        account.get_name_by_user_id(finance.transaction_master.verified_by_user_id),
        finance.transaction_master.verification_status_id
    FROM finance.transaction_master
    INNER JOIN finance.transaction_details
    ON finance.transaction_master.transaction_master_id = finance.transaction_details.transaction_master_id
    WHERE finance.transaction_master.verification_status_id > 0
    AND finance.transaction_master.value_date >= _value_date_from
    AND finance.transaction_master.value_date <= _value_date_to
    AND finance.transaction_master.office_id IN (SELECT * FROM core.get_office_ids(_office_id)) 
    AND finance.transaction_details.account_id IN (SELECT * FROM finance.get_account_ids(_account_id))
    AND NOT finance.transaction_master.deleted
    ORDER BY 
        finance.transaction_master.book_date,
        finance.transaction_master.value_date,
        finance.transaction_master.last_verified_on;



    UPDATE temp_account_statement
    SET balance = c.balance
    FROM
    (
        SELECT
            temp_account_statement.id, 
            SUM(COALESCE(c.credit, 0)) 
            - 
            SUM(COALESCE(c.debit,0)) As balance
        FROM temp_account_statement
        LEFT JOIN temp_account_statement AS c 
            ON (c.id <= temp_account_statement.id)
        GROUP BY temp_account_statement.id
        ORDER BY temp_account_statement.id
    ) AS c
    WHERE temp_account_statement.id = c.id;


    UPDATE temp_account_statement SET 
        account_number = finance.accounts.account_number,
        account = finance.accounts.account_name
    FROM finance.accounts
    WHERE temp_account_statement.account_id = finance.accounts.account_id;


--     UPDATE temp_account_statement SET
--         flag_bg = core.get_flag_background_color(core.get_flag_type_id(_user_id, 'account_statement', 'transaction_code', temp_account_statement.tran_code::text)),
--         flag_fg = core.get_flag_foreground_color(core.get_flag_type_id(_user_id, 'account_statement', 'transaction_code', temp_account_statement.tran_code::text));


    IF(_normally_debit) THEN
        UPDATE temp_account_statement SET balance = temp_account_statement.balance * -1;
    END IF;

    RETURN QUERY
    SELECT * FROM temp_account_statement;
END;
$$
LANGUAGE plpgsql;

--SELECT * FROM finance.get_account_statement('1-1-2010','1-1-2020',1,1,1);


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_balance_sheet.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_balance_sheet
(
    _previous_period                date,
    _current_period                 date,
    _user_id                        integer,
    _office_id                      integer,
    _factor                         integer
);

CREATE FUNCTION finance.get_balance_sheet
(
    _previous_period                date,
    _current_period                 date,
    _user_id                        integer,
    _office_id                      integer,
    _factor                         integer
)
RETURNS TABLE
(
    id                              bigint,
    item                            text,
    previous_period                 decimal(24, 4),
    current_period                  decimal(24, 4),
    account_id                      integer,
    account_number                  text,
    is_retained_earning             boolean
)
AS
$$
    DECLARE this                    RECORD;
    DECLARE _date_from              date;
BEGIN
    _date_from := finance.get_fiscal_year_start_date(_office_id);

    IF(COALESCE(_factor, 0) = 0) THEN
        _factor := 1;
    END IF;

    DROP TABLE IF EXISTS bs_temp;
    CREATE TEMPORARY TABLE bs_temp
    (
        item_id                     int PRIMARY KEY,
        item                        text,
        account_number              text,
        account_id                  integer,
        child_accounts              integer[],
        parent_item_id              integer REFERENCES bs_temp(item_id),
        is_debit                    boolean DEFAULT(false),
        previous_period             decimal(24, 4) DEFAULT(0),
        current_period              decimal(24, 4) DEFAULT(0),
        sort                        int,
        skip                        boolean DEFAULT(false),
        is_retained_earning         boolean DEFAULT(false)
    ) ON COMMIT DROP;
    
    --BS structure setup start
    INSERT INTO bs_temp(item_id, item, parent_item_id)
    SELECT  1,       'Assets',                              NULL::numeric   UNION ALL
    SELECT  10100,   'Current Assets',                      1               UNION ALL
    SELECT  10101,   'Cash A/C',                            1               UNION ALL
    SELECT  10102,   'Bank A/C',                            1               UNION ALL
    SELECT  10110,   'Accounts Receivable',                 10100           UNION ALL
    SELECT  10200,   'Fixed Assets',                        1               UNION ALL
    SELECT  10201,   'Property, Plants, and Equipments',    10201           UNION ALL
    SELECT  10300,   'Other Assets',                        1               UNION ALL
    SELECT  14900,   'Liabilities & Shareholders'' Equity', NULL            UNION ALL
    SELECT  15000,   'Current Liabilities',                 14900           UNION ALL
    SELECT  15010,   'Accounts Payable',                    15000           UNION ALL
    SELECT  15011,   'Salary Payable',                      15000           UNION ALL
    SELECT  15100,   'Long-Term Liabilities',               14900           UNION ALL
    SELECT  15200,   'Shareholders'' Equity',               14900           UNION ALL
    SELECT  15300,   'Retained Earnings',                   15200;

    UPDATE bs_temp SET is_debit = true WHERE bs_temp.item_id <= 10300;
    UPDATE bs_temp SET is_retained_earning = true WHERE bs_temp.item_id = 15300;
    
    INSERT INTO bs_temp(item_id, account_id, account_number, parent_item_id, item, is_debit, child_accounts)
    SELECT 
        row_number() OVER(ORDER BY finance.accounts.account_master_id) + (finance.accounts.account_master_id * 100) AS id,
        finance.accounts.account_id,
        finance.accounts.account_number,
        finance.accounts.account_master_id,
        finance.accounts.account_name,
        finance.account_masters.normally_debit,
        array_agg(agg)
    FROM finance.accounts
    INNER JOIN finance.account_masters
    ON finance.accounts.account_master_id = finance.account_masters.account_master_id,
    finance.get_account_ids(finance.accounts.account_id) as agg
    WHERE parent_account_id IN
    (
        SELECT finance.accounts.account_id
        FROM finance.accounts
        WHERE finance.accounts.sys_type
        AND finance.accounts.account_master_id BETWEEN 10100 AND 15200
    )
    AND finance.accounts.account_master_id BETWEEN 10100 AND 15200
    GROUP BY finance.accounts.account_id, finance.account_masters.normally_debit
    ORDER BY account_master_id;


    --Updating credit balances of individual GL accounts.
    UPDATE bs_temp SET previous_period = tran.previous_period
    FROM
    (
        SELECT 
            bs_temp.account_id,         
            SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END) AS previous_period
        FROM bs_temp
        INNER JOIN finance.verified_transaction_mat_view
        ON finance.verified_transaction_mat_view.account_id = ANY(bs_temp.child_accounts)
        WHERE value_date <=_previous_period
        AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        GROUP BY bs_temp.account_id
    ) AS tran
    WHERE bs_temp.account_id = tran.account_id;

    --Updating credit balances of individual GL accounts.
    UPDATE bs_temp SET current_period = tran.current_period
    FROM
    (
        SELECT 
            bs_temp.account_id,         
            SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END) AS current_period
        FROM bs_temp
        INNER JOIN finance.verified_transaction_mat_view
        ON finance.verified_transaction_mat_view.account_id = ANY(bs_temp.child_accounts)
        WHERE value_date <=_current_period
        AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        GROUP BY bs_temp.account_id
    ) AS tran
    WHERE bs_temp.account_id = tran.account_id;


    --Dividing by the factor.
    UPDATE bs_temp SET 
        previous_period = bs_temp.previous_period / _factor,
        current_period = bs_temp.current_period / _factor;

    --Upading balance of retained earnings
    UPDATE bs_temp SET 
        previous_period = finance.get_retained_earnings(_previous_period, _office_id, _factor),
        current_period = finance.get_retained_earnings(_current_period, _office_id, _factor)
    WHERE bs_temp.item_id = 15300;

    --Reversing assets to debit balance.
    UPDATE bs_temp SET 
        previous_period=bs_temp.previous_period*-1,
        current_period=bs_temp.current_period*-1 
    WHERE bs_temp.is_debit;



    FOR this IN 
    SELECT * FROM bs_temp 
    WHERE COALESCE(bs_temp.previous_period, 0) + COALESCE(bs_temp.current_period, 0) != 0 
    AND bs_temp.account_id IS NOT NULL
    LOOP
        UPDATE bs_temp SET skip = true WHERE this.account_id = ANY(bs_temp.child_accounts)
        AND bs_temp.account_id != this.account_id;
    END LOOP;

    --Updating current period amount on GL parent item by the sum of their respective child balances.
    WITH running_totals AS
    (
        SELECT bs_temp.parent_item_id,
        SUM(COALESCE(bs_temp.previous_period, 0)) AS previous_period,
        SUM(COALESCE(bs_temp.current_period, 0)) AS current_period
        FROM bs_temp
        WHERE NOT skip
        AND parent_item_id IS NOT NULL
        GROUP BY bs_temp.parent_item_id
    )
    UPDATE bs_temp SET 
        previous_period = running_totals.previous_period,
        current_period = running_totals.current_period
    FROM running_totals
    WHERE running_totals.parent_item_id = bs_temp.item_id
    AND bs_temp.item_id
    IN
    (
        SELECT parent_item_id FROM running_totals
    );


    --Updating sum amount on parent item by the sum of their respective child balances.
    UPDATE bs_temp SET 
        previous_period = tran.previous_period,
        current_period = tran.current_period
    FROM 
    (
        SELECT bs_temp.parent_item_id,
        SUM(bs_temp.previous_period) AS previous_period,
        SUM(bs_temp.current_period) AS current_period
        FROM bs_temp
        WHERE bs_temp.parent_item_id IS NOT NULL
        GROUP BY bs_temp.parent_item_id
    ) 
    AS tran 
    WHERE tran.parent_item_id = bs_temp.item_id
    AND tran.parent_item_id IS NOT NULL;


    --Updating sum amount on grandparents.
    UPDATE bs_temp SET 
        previous_period = tran.previous_period,
        current_period = tran.current_period
    FROM 
    (
        SELECT bs_temp.parent_item_id,
        SUM(bs_temp.previous_period) AS previous_period,
        SUM(bs_temp.current_period) AS current_period
        FROM bs_temp
        WHERE bs_temp.parent_item_id IS NOT NULL
        GROUP BY bs_temp.parent_item_id
    ) 
    AS tran 
    WHERE tran.parent_item_id = bs_temp.item_id;

    --Removing ledgers having zero balances
    DELETE FROM bs_temp
    WHERE COALESCE(bs_temp.previous_period, 0) + COALESCE(bs_temp.current_period, 0) = 0
    AND bs_temp.account_id IS NOT NULL;

    --Converting 0's to NULLS.
    UPDATE bs_temp SET previous_period = CASE WHEN bs_temp.previous_period = 0 THEN NULL ELSE bs_temp.previous_period END;
    UPDATE bs_temp SET current_period = CASE WHEN bs_temp.current_period = 0 THEN NULL ELSE bs_temp.current_period END;
    
    UPDATE bs_temp SET sort = bs_temp.item_id WHERE bs_temp.item_id < 15400;
    UPDATE bs_temp SET sort = bs_temp.parent_item_id WHERE bs_temp.item_id >= 15400;

    RETURN QUERY
    SELECT
        row_number() OVER(order by bs_temp.sort, bs_temp.item_id) AS id,
        bs_temp.item,
        bs_temp.previous_period,
        bs_temp.current_period,
        bs_temp.account_id,
        bs_temp.account_number,
        bs_temp.is_retained_earning
    FROM bs_temp;
END;
$$
LANGUAGE plpgsql;

--SELECT * FROM finance.get_balance_sheet('7/17/2014', '7/16/2015', 2, 2, 1000);


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_cash_flow_heading_id_by_cash_flow_heading_code.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_cash_flow_heading_id_by_cash_flow_heading_code(_cash_flow_heading_code national character varying(12));

CREATE FUNCTION finance.get_cash_flow_heading_id_by_cash_flow_heading_code(_cash_flow_heading_code national character varying(12))
RETURNS integer
STABLE
AS
$$
BEGIN
    RETURN
        cash_flow_heading_id
    FROM
        finance.cash_flow_headings
    WHERE
        finance.cash_flow_headings.cash_flow_heading_code = $1
	AND NOT finance.cash_flow_headings.deleted;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_cash_repository_balance.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_cash_repository_balance(_cash_repository_id integer, _currency_code national character varying(12));
CREATE FUNCTION finance.get_cash_repository_balance(_cash_repository_id integer, _currency_code national character varying(12))
RETURNS public.money_strict2
AS
$$
    DECLARE _debit public.money_strict2;
    DECLARE _credit public.money_strict2;
BEGIN
    SELECT COALESCE(SUM(amount_in_currency), 0::public.money_strict2) INTO _debit
    FROM finance.verified_transaction_view
    WHERE cash_repository_id=$1
    AND currency_code=$2
    AND tran_type='Dr';

    SELECT COALESCE(SUM(amount_in_currency), 0::public.money_strict2) INTO _credit
    FROM finance.verified_transaction_view
    WHERE cash_repository_id=$1
    AND currency_code=$2
    AND tran_type='Cr';

    RETURN _debit - _credit;
END
$$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS finance.get_cash_repository_balance(_cash_repository_id integer);
CREATE FUNCTION finance.get_cash_repository_balance(_cash_repository_id integer)
RETURNS public.money_strict2
AS
$$
    DECLARE _local_currency_code national character varying(12) = finance.get_default_currency_code($1);
    DECLARE _debit public.money_strict2;
    DECLARE _credit public.money_strict2;
BEGIN
    SELECT COALESCE(SUM(amount_in_currency), 0::public.money_strict2) INTO _debit
    FROM finance.verified_transaction_view
    WHERE cash_repository_id=$1
    AND currency_code=_local_currency_code
    AND tran_type='Dr';

    SELECT COALESCE(SUM(amount_in_currency), 0::public.money_strict2) INTO _credit
    FROM finance.verified_transaction_view
    WHERE cash_repository_id=$1
    AND currency_code=_local_currency_code
    AND tran_type='Cr';

    RETURN _debit - _credit;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_cash_repository_id_by_cash_repository_code.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_cash_repository_id_by_cash_repository_code(text);
CREATE FUNCTION finance.get_cash_repository_id_by_cash_repository_code(text)
RETURNS integer
AS
$$
BEGIN
    RETURN
    (
        SELECT cash_repository_id
        FROM finance.cash_repositories
        WHERE finance.cash_repositories.cash_repository_code=$1
		AND NOT finance.cash_repositories.deleted
    );
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_cash_repository_id_by_cash_repository_name.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_cash_repository_id_by_cash_repository_name(text);
CREATE FUNCTION finance.get_cash_repository_id_by_cash_repository_name(text)
RETURNS integer
AS
$$
BEGIN
    RETURN
    (
        SELECT cash_repository_id
        FROM finance.cash_repositories
        WHERE finance.cash_repositories.cash_repository_name=$1
		AND NOT finance.cash_repositories.deleted
    );
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_cost_center_id_by_cost_center_code.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_cost_center_id_by_cost_center_code(text);

CREATE FUNCTION finance.get_cost_center_id_by_cost_center_code(text)
RETURNS integer
STABLE
AS
$$
BEGIN
    RETURN cost_center_id
    FROM finance.cost_centers
    WHERE finance.cost_centers.cost_center_code=$1
	AND NOT finance.cost_centers.deleted;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_default_currency_code.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_default_currency_code(cash_repository_id integer);

CREATE FUNCTION finance.get_default_currency_code(cash_repository_id integer)
RETURNS national character varying(12)
AS
$$
BEGIN
    RETURN
    (
        SELECT core.offices.currency_code 
        FROM finance.cash_repositories
        INNER JOIN core.offices
        ON core.offices.office_id = finance.cash_repositories.office_id
        WHERE finance.cash_repositories.cash_repository_id=$1
		AND NOT finance.cash_repositories.deleted	
    );
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_default_currency_code_by_office_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_default_currency_code_by_office_id(office_id integer);

CREATE FUNCTION finance.get_default_currency_code_by_office_id(office_id integer)
RETURNS national character varying(12)
AS
$$
BEGIN
    RETURN
    (
        SELECT core.offices.currency_code 
        FROM core.offices
        WHERE core.offices.office_id = $1
		AND NOT core.offices.deleted	
    );
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_exchange_rate.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_exchange_rate(office_id integer, currency_code national character varying(12));

CREATE FUNCTION finance.get_exchange_rate(office_id integer, currency_code national character varying(12))
RETURNS decimal_strict2
AS
$$
    DECLARE _local_currency_code national character varying(12)= '';
    DECLARE _unit integer_strict2 = 0;
    DECLARE _exchange_rate decimal_strict2=0;
BEGIN
    SELECT core.offices.currency_code
    INTO _local_currency_code
    FROM core.offices
    WHERE core.offices.office_id=$1
	AND NOT core.offices.deleted;

    IF(_local_currency_code = $2) THEN
        RETURN 1;
    END IF;

    SELECT unit, exchange_rate
    INTO _unit, _exchange_rate
    FROM finance.exchange_rate_details
    INNER JOIN finance.exchange_rates
    ON finance.exchange_rate_details.exchange_rate_id = finance.exchange_rates.exchange_rate_id
    WHERE finance.exchange_rates.office_id=$1
    AND foreign_currency_code=$2;

    IF(_unit = 0) THEN
        RETURN 0;
    END IF;
    
    RETURN _exchange_rate/_unit;    
END
$$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS finance.get_exchange_rate(office_id integer, source_currency_code national character varying(12), destination_currency_code national character varying(12));

CREATE FUNCTION finance.get_exchange_rate(office_id integer, source_currency_code national character varying(12), destination_currency_code national character varying(12))
RETURNS decimal_strict2
AS
$$
    DECLARE _unit integer_strict2 = 0;
    DECLARE _exchange_rate decimal_strict2=0;
    DECLARE _from_source_currency decimal_strict2=0;
    DECLARE _from_destination_currency decimal_strict2=0;
BEGIN
    IF($2 = $3) THEN
        RETURN 1;
    END IF;


    _from_source_currency := finance.get_exchange_rate($1, $2);
    _from_destination_currency := finance.get_exchange_rate($1, $3);
        
    RETURN _from_source_currency / _from_destination_currency ; 
END
$$
LANGUAGE plpgsql;

--SELECT * FROM  finance.get_exchange_rate(1, 'USD')


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_frequencies.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_frequencies(_frequency_id integer);

CREATE FUNCTION  finance.get_frequencies(_frequency_id integer)
RETURNS integer[]
IMMUTABLE
AS
$$
    DECLARE _frequencies integer[];
BEGIN
    IF(_frequency_id = 2) THEN--End of month
        --End of month
        --End of quarter is also end of third/ninth month
        --End of half is also end of sixth month
        --End of year is also end of twelfth month
        _frequencies = ARRAY[2, 3, 4, 5];
    ELSIF(_frequency_id = 3) THEN--End of quarter
        --End of quarter
        --End of half is the second end of quarter
        --End of year is the fourth/last end of quarter
        _frequencies = ARRAY[3, 4, 5];
    ELSIF(_frequency_id = 4) THEN--End of half
        --End of half
        --End of year is the second end of half
        _frequencies = ARRAY[4, 5];
    ELSIF(_frequency_id = 5) THEN--End of year
        --End of year
        _frequencies = ARRAY[5];
    END IF;

    RETURN _frequencies;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_frequency_end_date.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_frequency_end_date(_frequency_id integer, _value_date date);

CREATE FUNCTION finance.get_frequency_end_date(_frequency_id integer, _value_date date)
RETURNS date
STABLE
AS
$$
    DECLARE _end_date date;
BEGIN
    SELECT MIN(value_date)
    INTO _end_date
    FROM finance.frequency_setups
    WHERE value_date > $2
    AND frequency_id = ANY( finance.get_frequencies($1));

    RETURN _end_date;
END
$$
LANGUAGE plpgsql;

--SELECT * FROM finance.get_frequency_end_date(1, '1-1-2000');

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_frequency_setup_code_by_frequency_setup_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_frequency_setup_code_by_frequency_setup_id(_frequency_setup_id integer);

CREATE FUNCTION finance.get_frequency_setup_code_by_frequency_setup_id(_frequency_setup_id integer)
RETURNS text
STABLE
AS
$$
BEGIN
    RETURN frequency_setup_code
    FROM finance.frequency_setups
    WHERE finance.frequency_setups.frequency_setup_id = $1
	AND NOT finance.frequency_setups.deleted;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_frequency_setup_end_date_by_frequency_setup_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_frequency_setup_end_date_by_frequency_setup_id(_frequency_setup_id integer);
CREATE FUNCTION finance.get_frequency_setup_end_date_by_frequency_setup_id(_frequency_setup_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN
        value_date
    FROM
        finance.frequency_setups
    WHERE
        finance.frequency_setups.frequency_setup_id = $1
	AND NOT finance.frequency_setups.deleted;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_frequency_setup_start_date_by_frequency_setup_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_frequency_setup_start_date_by_frequency_setup_id(_frequency_setup_id integer);
CREATE FUNCTION finance.get_frequency_setup_start_date_by_frequency_setup_id(_frequency_setup_id integer)
RETURNS date
AS
$$
    DECLARE _start_date date;
BEGIN
    SELECT MAX(value_date) + 1 
    INTO _start_date
    FROM finance.frequency_setups
    WHERE finance.frequency_setups.value_date < 
    (
        SELECT value_date
        FROM finance.frequency_setups
        WHERE finance.frequency_setups.frequency_setup_id = $1
		AND NOT finance.frequency_setups.deleted
    )
	AND NOT finance.frequency_setups.deleted;

    IF(_start_date IS NULL) THEN
        SELECT starts_from 
        INTO _start_date
        FROM finance.fiscal_year
		WHERE NOT finance.fiscal_year.deleted;
    END IF;

    RETURN _start_date;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_frequency_setup_start_date_frequency_setup_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_frequency_setup_start_date_frequency_setup_id(_frequency_setup_id integer);
CREATE FUNCTION finance.get_frequency_setup_start_date_frequency_setup_id(_frequency_setup_id integer)
RETURNS date
AS
$$
    DECLARE _start_date date;
BEGIN
    SELECT MAX(value_date) + 1 
    INTO _start_date
    FROM finance.frequency_setups
    WHERE finance.frequency_setups.value_date < 
    (
        SELECT value_date
        FROM finance.frequency_setups
        WHERE finance.frequency_setups.frequency_setup_id = $1
		AND NOT finance.frequency_setups.deleted
    )
	AND NOT finance.frequency_setups.deleted;

    IF(_start_date IS NULL) THEN
        SELECT starts_from 
        INTO _start_date
        FROM finance.fiscal_year
		WHERE NOT finance.fiscal_year.deleted;
    END IF;

    RETURN _start_date;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_income_tax_provison_amount.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_income_tax_provison_amount(_office_id integer, _profit  decimal(24, 4), _balance  decimal(24, 4));

CREATE FUNCTION finance.get_income_tax_provison_amount(_office_id integer, _profit decimal(24, 4), _balance decimal(24, 4))
RETURNS  decimal(24, 4)
AS
$$
    DECLARE _rate real;
BEGIN
    _rate := finance.get_income_tax_rate(_office_id);

    RETURN
    (
        (_profit * _rate/100) - _balance
    );
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_income_tax_rate.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_income_tax_rate(_office_id integer);

CREATE FUNCTION finance.get_income_tax_rate(_office_id integer)
RETURNS public.decimal_strict
AS
$$
BEGIN
    RETURN income_tax_rate
    FROM finance.tax_setups
    WHERE finance.tax_setups.office_id = _office_id
    AND NOT finance.tax_setups.deleted;
        
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_journal_view.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_journal_view
(
    _user_id                        integer,
    _office_id                      integer,
    _from                           date,
    _to                             date,
    _tran_id                        bigint,
    _tran_code                      national character varying(50),
    _book                           national character varying(50),
    _reference_number               national character varying(50),
    _statement_reference            national character varying(50),
    _posted_by                      national character varying(50),
    _office                         national character varying(50),
    _status                         national character varying(12),
    _verified_by                    national character varying(50),
    _reason                         national character varying(128)
);

CREATE FUNCTION finance.get_journal_view
(
    _user_id                        integer,
    _office_id                      integer,
    _from                           date,
    _to                             date,
    _tran_id                        bigint,
    _tran_code                      national character varying(50),
    _book                           national character varying(50),
    _reference_number               national character varying(50),
    _statement_reference            national character varying(50),
    _posted_by                      national character varying(50),
    _office                         national character varying(50),
    _status                         national character varying(12),
    _verified_by                    national character varying(50),
    _reason                         national character varying(128)
)
RETURNS TABLE
(
    transaction_master_id           bigint,
    transaction_code                national character varying(50),
    book                            national character varying(50),
    value_date                      date,
    book_date                      	date,
    reference_number                national character varying(24),
    statement_reference             text,
    posted_by                       text,
    office                          text,
    status                          text,
    verified_by                     text,
    verified_on                     TIMESTAMP WITH TIME ZONE,
    reason                          national character varying(128),
    transaction_ts                  TIMESTAMP WITH TIME ZONE
)
AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE office_cte(office_id) AS 
    (
        SELECT _office_id
        UNION ALL
        SELECT
            c.office_id
        FROM 
        office_cte AS p, 
        core.offices AS c 
        WHERE 
        parent_office_id = p.office_id
    )

    SELECT 
        finance.transaction_master.transaction_master_id, 
        finance.transaction_master.transaction_code,
        finance.transaction_master.book,
        finance.transaction_master.value_date,
        finance.transaction_master.book_date,
        finance.transaction_master.reference_number,
        finance.transaction_master.statement_reference,
        account.get_name_by_user_id(finance.transaction_master.user_id) as posted_by,
        core.get_office_name_by_office_id(finance.transaction_master.office_id) as office,
        finance.get_verification_status_name_by_verification_status_id(finance.transaction_master.verification_status_id) as status,
        account.get_name_by_user_id(finance.transaction_master.verified_by_user_id) as verified_by,
        finance.transaction_master.last_verified_on AS verified_on,
        finance.transaction_master.verification_reason AS reason,    
        finance.transaction_master.transaction_ts
    FROM finance.transaction_master
    WHERE 1 = 1
    AND finance.transaction_master.value_date BETWEEN _from AND _to
    AND office_id IN (SELECT office_id FROM office_cte)
    AND (_tran_id = 0 OR _tran_id  = finance.transaction_master.transaction_master_id)
    AND LOWER(finance.transaction_master.transaction_code) LIKE '%' || LOWER(_tran_code) || '%' 
    AND LOWER(finance.transaction_master.book) LIKE '%' || LOWER(_book) || '%' 
    AND COALESCE(LOWER(finance.transaction_master.reference_number), '') LIKE '%' || LOWER(_reference_number) || '%' 
    AND COALESCE(LOWER(finance.transaction_master.statement_reference), '') LIKE '%' || LOWER(_statement_reference) || '%' 
    AND COALESCE(LOWER(finance.transaction_master.verification_reason), '') LIKE '%' || LOWER(_reason) || '%' 
    AND LOWER(account.get_name_by_user_id(finance.transaction_master.user_id)) LIKE '%' || LOWER(_posted_by) || '%' 
    AND LOWER(core.get_office_name_by_office_id(finance.transaction_master.office_id)) LIKE '%' || LOWER(_office) || '%' 
    AND COALESCE(LOWER(finance.get_verification_status_name_by_verification_status_id(finance.transaction_master.verification_status_id)), '') LIKE '%' || LOWER(_status) || '%' 
    AND COALESCE(LOWER(account.get_name_by_user_id(finance.transaction_master.verified_by_user_id)), '') LIKE '%' || LOWER(_verified_by) || '%'    
    AND NOT finance.transaction_master.deleted
	ORDER BY value_date ASC, verification_status_id DESC;
END
$$
LANGUAGE plpgsql;


--SELECT * FROM finance.get_journal_view(2,1,'1-1-2000','1-1-2020',0,'', 'Inventory Transfer', '', '','', '','','', '');




-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_net_profit.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_net_profit
(
    _date_from                      date,
    _date_to                        date,
    _office_id                      integer,
    _factor                         integer,
    _no_provison                    boolean
);

CREATE FUNCTION finance.get_net_profit
(
    _date_from                      date,
    _date_to                        date,
    _office_id                      integer,
    _factor                         integer,
    _no_provison                    boolean DEFAULT false
)
RETURNS decimal(24, 4)
AS
$$
    DECLARE _incomes                decimal(24, 4) = 0;
    DECLARE _expenses               decimal(24, 4) = 0;
    DECLARE _profit_before_tax      decimal(24, 4) = 0;
    DECLARE _tax_paid               decimal(24, 4) = 0;
    DECLARE _tax_provison           decimal(24, 4) = 0;
BEGIN
    SELECT SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END)
    INTO _incomes
    FROM finance.verified_transaction_mat_view
    WHERE value_date >= _date_from AND value_date <= _date_to
    AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
    AND account_master_id >=20100
    AND account_master_id <= 20300;
    
    SELECT SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END)
    INTO _expenses
    FROM finance.verified_transaction_mat_view
    WHERE value_date >= _date_from AND value_date <= _date_to
    AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
    AND account_master_id >=20400
    AND account_master_id <= 20701;
    
    SELECT SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END)
    INTO _tax_paid
    FROM finance.verified_transaction_mat_view
    WHERE value_date >= _date_from AND value_date <= _date_to
    AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
    AND account_master_id =20800;
    
    _profit_before_tax := COALESCE(_incomes, 0) - COALESCE(_expenses, 0);

    IF(_no_provison) THEN
        RETURN (_profit_before_tax - COALESCE(_tax_paid, 0)) / _factor;
    END IF;
    
    _tax_provison      := finance.get_income_tax_provison_amount(_office_id, _profit_before_tax, COALESCE(_tax_paid, 0));
    
    RETURN (_profit_before_tax - (COALESCE(_tax_provison, 0) + COALESCE(_tax_paid, 0))) / _factor;
END
$$
LANGUAGE plpgsql;

--SELECT * FROM finance.get_net_profit('1-1-2000', '1-1-2020', 1, 1, false);

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_new_transaction_counter.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_new_transaction_counter(date);

CREATE FUNCTION finance.get_new_transaction_counter(date)
RETURNS integer
AS
$$
    DECLARE _ret_val integer;
BEGIN
    SELECT INTO _ret_val
        COALESCE(MAX(transaction_counter),0)
    FROM finance.transaction_master
    WHERE finance.transaction_master.value_date=$1
	AND NOT finance.transaction_master.deleted;

    IF _ret_val IS NULL THEN
        RETURN 1::integer;
    ELSE
        RETURN (_ret_val + 1)::integer;
    END IF;
END;
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_office_id_by_cash_repository_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_office_id_by_cash_repository_id(integer);

CREATE FUNCTION finance.get_office_id_by_cash_repository_id(integer)
RETURNS integer
AS
$$
BEGIN
        RETURN office_id
        FROM finance.cash_repositories
        WHERE finance.cash_repositories.cash_repository_id=$1
		AND NOT finance.cash_repositories.deleted;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_periods.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_periods
(
    _date_from                      date,
    _date_to                        date
);

CREATE FUNCTION finance.get_periods
(
    _date_from                      date,
    _date_to                        date
)
RETURNS finance.period[]
VOLATILE
AS
$$
BEGIN
    DROP TABLE IF EXISTS frequency_setups_temp;
    CREATE TEMPORARY TABLE frequency_setups_temp
    (
        frequency_setup_id      int,
        value_date              date
    ) ON COMMIT DROP;

    INSERT INTO frequency_setups_temp
    SELECT frequency_setup_id, value_date
    FROM finance.frequency_setups
    WHERE finance.frequency_setups.value_date BETWEEN _date_from AND _date_to
	AND NOT finance.frequency_setups.deleted
    ORDER BY value_date;

    RETURN
        array_agg
        (
            (
                finance.get_frequency_setup_code_by_frequency_setup_id(frequency_setup_id),
                finance.get_frequency_setup_start_date_by_frequency_setup_id(frequency_setup_id),
                finance.get_frequency_setup_end_date_by_frequency_setup_id(frequency_setup_id)
            )::finance.period
        )::finance.period[]
    FROM frequency_setups_temp;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_retained_earnings_statement.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_retained_earnings_statement
(
    _date_to                        date,
    _office_id                      integer,
    _factor                         integer    
);

CREATE FUNCTION finance.get_retained_earnings_statement
(
    _date_to                        date,
    _office_id                      integer,
    _factor                         integer    
)
RETURNS TABLE
(
    id                              integer,
    value_date                      date,
    tran_code                       text,
    statement_reference             text,
    debit                           decimal(24, 4),
    credit                          decimal(24, 4),
    balance                         decimal(24, 4),
    office                          text,
    book                            text,
    account_id                      integer,
    account_number                  text,
    account                         text,
    posted_on                       TIMESTAMP WITH TIME ZONE,
    posted_by                       text,
    approved_by                     text,
    verification_status             integer
)
AS
$$
    DECLARE _accounts               integer[];
    DECLARE _date_from              date;
    DECLARE _net_profit             decimal(24, 4)  = 0;
    DECLARE _income_tax_rate        real            = 0;
    DECLARE _itp                    decimal(24, 4)  = 0;
BEGIN
    _date_from                      := finance.get_fiscal_year_start_date(_office_id);
    _net_profit                     := finance.get_net_profit(_date_from, _date_to, _office_id, _factor);
    _income_tax_rate                := finance.get_income_tax_rate(_office_id);

    IF(COALESCE(_factor , 0) = 0) THEN
        _factor                         := 1;
    END IF; 

    IF(_income_tax_rate != 0) THEN
        _itp                            := (_net_profit * _income_tax_rate) / (100 - _income_tax_rate);
    END IF;

    DROP TABLE IF EXISTS temp_account_statement;
    CREATE TEMPORARY TABLE temp_account_statement
    (
        id                          SERIAL,
        value_date                  date,
        tran_code                   text,
        statement_reference         text,
        debit                       decimal(24, 4),
        credit                      decimal(24, 4),
        balance                     decimal(24, 4),
        office                      text,
        book                        text,
        account_id                  integer,
        account_number              text,
        account                     text,
        posted_on                   TIMESTAMP WITH TIME ZONE,
        posted_by                   text,
        approved_by                 text,
        verification_status         integer
    ) ON COMMIT DROP;

    SELECT array_agg(finance.accounts.account_id) INTO _accounts
    FROM finance.accounts
    WHERE finance.accounts.account_master_id BETWEEN 15300 AND 15400;

    INSERT INTO temp_account_statement(value_date, tran_code, statement_reference, debit, credit, office, book, account_id, posted_on, posted_by, approved_by, verification_status)
    SELECT
        _date_from,
        NULL,
        'Beginning balance on this fiscal year.',
        NULL,
        SUM
        (
            CASE finance.transaction_details.tran_type
            WHEN 'Cr' THEN amount_in_local_currency
            ELSE amount_in_local_currency * -1 
            END            
        ) as credit,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    FROM finance.transaction_master
    INNER JOIN finance.transaction_details
    ON finance.transaction_master.transaction_master_id = finance.transaction_details.transaction_master_id
    WHERE
        finance.transaction_master.verification_status_id > 0
    AND
        finance.transaction_master.value_date < _date_from
    AND
       finance.transaction_master.office_id IN (SELECT * FROM core.get_office_ids(_office_id)) 
    AND
       finance.transaction_details.account_id = ANY(_accounts);

    INSERT INTO temp_account_statement(value_date, tran_code, statement_reference, debit, credit)
    SELECT _date_to, '', format('Add: Net Profit as on %1$s.', _date_to::text), 0, _net_profit;

    INSERT INTO temp_account_statement(value_date, tran_code, statement_reference, debit, credit)
    SELECT _date_to, '', 'Add: Income Tax provison.', 0, _itp;

--     DELETE FROM temp_account_statement
--     WHERE COALESCE(temp_account_statement.debit, 0) = 0
--     AND COALESCE(temp_account_statement.credit, 0) = 0;
    

    UPDATE temp_account_statement SET 
    debit = temp_account_statement.credit * -1,
    credit = 0
    WHERE temp_account_statement.credit < 0;


    INSERT INTO temp_account_statement(value_date, tran_code, statement_reference, debit, credit, office, book, account_id, posted_on, posted_by, approved_by, verification_status)
    SELECT
        finance.transaction_master.value_date,
        finance.transaction_master. transaction_code,
        finance.transaction_details.statement_reference,
        CASE finance.transaction_details.tran_type
        WHEN 'Dr' THEN amount_in_local_currency / _factor
        ELSE NULL END,
        CASE finance.transaction_details.tran_type
        WHEN 'Cr' THEN amount_in_local_currency / _factor
        ELSE NULL END,
        core.get_office_name_by_office_id(finance.transaction_master.office_id),
        finance.transaction_master.book,
        finance.transaction_details.account_id,
        finance.transaction_master.transaction_ts,
        account.get_name_by_user_id(finance.transaction_master.user_id),
        account.get_name_by_user_id(finance.transaction_master.verified_by_user_id),
        finance.transaction_master.verification_status_id
    FROM finance.transaction_master
    INNER JOIN finance.transaction_details
    ON finance.transaction_master.transaction_master_id = finance.transaction_details.transaction_master_id
    WHERE
        finance.transaction_master.verification_status_id > 0
    AND
        finance.transaction_master.value_date >= _date_from
    AND
        finance.transaction_master.value_date <= _date_to
    AND
       finance.transaction_master.office_id IN (SELECT * FROM core.get_office_ids(_office_id)) 
    AND
       finance.transaction_details.account_id = ANY(_accounts)
    ORDER BY 
        finance.transaction_master.value_date,
        finance.transaction_master.last_verified_on;


    UPDATE temp_account_statement
    SET balance = c.balance
    FROM
    (
        SELECT
            temp_account_statement.id, 
            SUM(COALESCE(c.credit, 0)) 
            - 
            SUM(COALESCE(c.debit,0)) As balance
        FROM temp_account_statement
        LEFT JOIN temp_account_statement AS c 
            ON (c.id <= temp_account_statement.id)
        GROUP BY temp_account_statement.id
        ORDER BY temp_account_statement.id
    ) AS c
    WHERE temp_account_statement.id = c.id;

    UPDATE temp_account_statement SET 
        account_number = finance.accounts.account_number,
        account = finance.accounts.account_name
    FROM finance.accounts
    WHERE temp_account_statement.account_id = finance.accounts.account_id;


    UPDATE temp_account_statement SET debit = NULL WHERE temp_account_statement.debit = 0;
    UPDATE temp_account_statement SET credit = NULL WHERE temp_account_statement.credit = 0;

    RETURN QUERY
    SELECT * FROM temp_account_statement
    ORDER BY id;    
END
$$
LANGUAGE plpgsql;


--SELECT * FROM finance.get_retained_earnings_statement('7/16/2015', 2, 1000);

--SELECT * FROM finance.get_retained_earnings('7/16/2015', 2, 100);



-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_root_account_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_root_account_id(bigint, bigint);

CREATE FUNCTION finance.get_root_account_id(_account_id bigint, _parent bigint default 0)
RETURNS integer
AS
$$
    DECLARE _parent_account_id bigint;
BEGIN
    SELECT 
        parent_account_id
        INTO _parent_account_id
    FROM finance.accounts
    WHERE finance.accounts.account_id=$1
	AND NOT finance.accounts.deleted;

    

    IF(_parent_account_id IS NULL) THEN
        RETURN $1;
    ELSE
        RETURN finance.get_root_account_id(_parent_account_id, $1);
    END IF; 
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_second_root_account_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_second_root_account_id(integer, integer);

CREATE FUNCTION finance.get_second_root_account_id(_account_id bigint, _parent bigint default 0)
RETURNS integer
AS
$$
    DECLARE _parent_account_id bigint;
BEGIN
    SELECT 
        parent_account_id
        INTO _parent_account_id
    FROM finance.accounts
    WHERE account_id=$1;

    IF(_parent_account_id IS NULL) THEN
        RETURN $2;
    ELSE
        RETURN finance.get_second_root_account_id(_parent_account_id, $1);
    END IF; 
END
$$
LANGUAGE plpgsql;



-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_transaction_code.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_transaction_code(value_date date, office_id integer, user_id integer, login_id bigint);

CREATE FUNCTION finance.get_transaction_code(value_date date, office_id integer, user_id integer, login_id bigint)
RETURNS text
AS
$$
    DECLARE _office_id bigint:=$2;
    DECLARE _user_id integer:=$3;
    DECLARE _login_id bigint:=$4;
    DECLARE _ret_val text;  
BEGIN
    _ret_val:= finance.get_new_transaction_counter($1)::text || '-' || TO_CHAR($1, 'YYYY-MM-DD') || '-' || CAST(_office_id as text) || '-' || CAST(_user_id as text) || '-' || CAST(_login_id as text)   || '-' ||  TO_CHAR(now(), 'HH24-MI-SS');
    RETURN _ret_val;
END
$$
LANGUAGE plpgsql;



-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_trial_balance.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_trial_balance
(
    _date_from                      date,
    _date_to                        date,
    _user_id                        integer,
    _office_id                      integer,
    _compact                        boolean,
    _factor                         decimal(24, 4),
    _change_side_when_negative      boolean,
    _include_zero_balance_accounts  boolean
);

CREATE FUNCTION finance.get_trial_balance
(
    _date_from                      date,
    _date_to                        date,
    _user_id                        integer,
    _office_id                      integer,
    _compact                        boolean,
    _factor                         decimal(24, 4),
    _change_side_when_negative      boolean DEFAULT(true),
    _include_zero_balance_accounts  boolean DEFAULT(true)
)
RETURNS TABLE
(
    id                      integer,
    account_id              integer,
    account_number          text,
    account                 text,
    previous_debit          decimal(24, 4),
    previous_credit         decimal(24, 4),
    debit                   decimal(24, 4),
    credit                  decimal(24, 4),
    closing_debit           decimal(24, 4),
    closing_credit          decimal(24, 4)
)
AS
$$
BEGIN
    IF(_date_from = 'infinity') THEN
        RAISE EXCEPTION 'Invalid date.'
        USING ERRCODE='P3008';
    END IF;

    IF NOT EXISTS
    (
        SELECT 0 FROM core.offices
        WHERE office_id IN 
        (
            SELECT * FROM core.get_office_ids(1)
        )
        HAVING count(DISTINCT currency_code) = 1
   ) THEN
        RAISE EXCEPTION 'Cannot produce trial balance of office(s) having different base currencies.'
        USING ERRCODE='P8002';
   END IF;


    DROP TABLE IF EXISTS temp_trial_balance;
    CREATE TEMPORARY TABLE temp_trial_balance
    (
        id                      integer,
        account_id              integer,
        account_number          text,
        account                 text,
        previous_debit          decimal(24, 4),
        previous_credit         decimal(24, 4),
        debit                   decimal(24, 4),
        credit                  decimal(24, 4),
        closing_debit           decimal(24, 4),
        closing_credit          decimal(24, 4),
        root_account_id         integer,
        normally_debit          boolean
    ) ON COMMIT DROP;

    INSERT INTO temp_trial_balance(account_id, previous_debit, previous_credit)    
    SELECT 
        verified_transaction_mat_view.account_id, 
        SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE 0 END),
        SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE 0 END)        
    FROM finance.verified_transaction_mat_view
    WHERE value_date < _date_from
    AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
    GROUP BY verified_transaction_mat_view.account_id;

    IF(_date_to = 'infinity') THEN
        INSERT INTO temp_trial_balance(account_id, debit, credit)    
        SELECT 
            verified_transaction_mat_view.account_id, 
            SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE 0 END),
            SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE 0 END)        
        FROM finance.verified_transaction_mat_view
        WHERE value_date > _date_from
        AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        GROUP BY verified_transaction_mat_view.account_id;
    ELSE
        INSERT INTO temp_trial_balance(account_id, debit, credit)    
        SELECT 
            verified_transaction_mat_view.account_id, 
            SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE 0 END),
            SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE 0 END)        
        FROM finance.verified_transaction_mat_view
        WHERE value_date >= _date_from AND value_date <= _date_to
        AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        GROUP BY verified_transaction_mat_view.account_id;    
    END IF;

    UPDATE temp_trial_balance SET root_account_id = finance.get_second_root_account_id(temp_trial_balance.account_id);


    DROP TABLE IF EXISTS temp_trial_balance2;
    
    IF(_compact) THEN
        CREATE TEMPORARY TABLE temp_trial_balance2
        ON COMMIT DROP
        AS
        SELECT
            temp_trial_balance.root_account_id AS account_id,
            ''::text as account_number,
            ''::text as account,
            SUM(temp_trial_balance.previous_debit) AS previous_debit,
            SUM(temp_trial_balance.previous_credit) AS previous_credit,
            SUM(temp_trial_balance.debit) AS debit,
            SUM(temp_trial_balance.credit) as credit,
            SUM(temp_trial_balance.closing_debit) AS closing_debit,
            SUM(temp_trial_balance.closing_credit) AS closing_credit,
            temp_trial_balance.normally_debit
        FROM temp_trial_balance
        GROUP BY 
            temp_trial_balance.root_account_id,
            temp_trial_balance.normally_debit
        ORDER BY temp_trial_balance.normally_debit;
    ELSE
        CREATE TEMPORARY TABLE temp_trial_balance2
        ON COMMIT DROP
        AS
        SELECT
            temp_trial_balance.account_id,
            ''::text as account_number,
            ''::text as account,
            SUM(temp_trial_balance.previous_debit) AS previous_debit,
            SUM(temp_trial_balance.previous_credit) AS previous_credit,
            SUM(temp_trial_balance.debit) AS debit,
            SUM(temp_trial_balance.credit) as credit,
            SUM(temp_trial_balance.closing_debit) AS closing_debit,
            SUM(temp_trial_balance.closing_credit) AS closing_credit,
            temp_trial_balance.normally_debit
        FROM temp_trial_balance
        GROUP BY 
            temp_trial_balance.account_id,
            temp_trial_balance.normally_debit
        ORDER BY temp_trial_balance.normally_debit;
    END IF;
    
    UPDATE temp_trial_balance2 SET
        account_number = finance.accounts.account_number,
        account = finance.accounts.account_name,
        normally_debit = finance.account_masters.normally_debit
    FROM finance.accounts
    INNER JOIN finance.account_masters
    ON finance.accounts.account_master_id = finance.account_masters.account_master_id
    WHERE temp_trial_balance2.account_id = finance.accounts.account_id;

    UPDATE temp_trial_balance2 SET 
        closing_debit = COALESCE(temp_trial_balance2.previous_debit, 0) + COALESCE(temp_trial_balance2.debit, 0),
        closing_credit = COALESCE(temp_trial_balance2.previous_credit, 0) + COALESCE(temp_trial_balance2.credit, 0);
        


     UPDATE temp_trial_balance2 SET previous_debit = COALESCE(temp_trial_balance2.previous_debit, 0) - COALESCE(temp_trial_balance2.previous_credit, 0), previous_credit = NULL WHERE normally_debit;
     UPDATE temp_trial_balance2 SET previous_credit = COALESCE(temp_trial_balance2.previous_credit, 0) - COALESCE(temp_trial_balance2.previous_debit, 0), previous_debit = NULL WHERE NOT normally_debit;
 
     UPDATE temp_trial_balance2 SET debit = COALESCE(temp_trial_balance2.debit, 0) - COALESCE(temp_trial_balance2.credit, 0), credit = NULL WHERE normally_debit;
     UPDATE temp_trial_balance2 SET credit = COALESCE(temp_trial_balance2.credit, 0) - COALESCE(temp_trial_balance2.debit, 0), debit = NULL WHERE NOT normally_debit;
 
     UPDATE temp_trial_balance2 SET closing_debit = COALESCE(temp_trial_balance2.closing_debit, 0) - COALESCE(temp_trial_balance2.closing_credit, 0), closing_credit = NULL WHERE normally_debit;
     UPDATE temp_trial_balance2 SET closing_credit = COALESCE(temp_trial_balance2.closing_credit, 0) - COALESCE(temp_trial_balance2.closing_debit, 0), closing_debit = NULL WHERE NOT normally_debit;


    IF(NOT _include_zero_balance_accounts) THEN
        DELETE FROM temp_trial_balance2 WHERE COALESCE(temp_trial_balance2.closing_debit) + COALESCE(temp_trial_balance2.closing_credit) = 0;
    END IF;
    
    IF(_factor > 0) THEN
        UPDATE temp_trial_balance2 SET previous_debit   = temp_trial_balance2.previous_debit/_factor;
        UPDATE temp_trial_balance2 SET previous_credit  = temp_trial_balance2.previous_credit/_factor;
        UPDATE temp_trial_balance2 SET debit            = temp_trial_balance2.debit/_factor;
        UPDATE temp_trial_balance2 SET credit           = temp_trial_balance2.credit/_factor;
        UPDATE temp_trial_balance2 SET closing_debit    = temp_trial_balance2.closing_debit/_factor;
        UPDATE temp_trial_balance2 SET closing_credit   = temp_trial_balance2.closing_credit/_factor;
    END IF;

    --Remove Zeros
    UPDATE temp_trial_balance2 SET previous_debit = NULL WHERE temp_trial_balance2.previous_debit = 0;
    UPDATE temp_trial_balance2 SET previous_credit = NULL WHERE temp_trial_balance2.previous_credit = 0;
    UPDATE temp_trial_balance2 SET debit = NULL WHERE temp_trial_balance2.debit = 0;
    UPDATE temp_trial_balance2 SET credit = NULL WHERE temp_trial_balance2.credit = 0;
    UPDATE temp_trial_balance2 SET closing_debit = NULL WHERE temp_trial_balance2.closing_debit = 0;
    UPDATE temp_trial_balance2 SET closing_debit = NULL WHERE temp_trial_balance2.closing_credit = 0;

    IF(_change_side_when_negative) THEN
        UPDATE temp_trial_balance2 SET previous_debit = temp_trial_balance2.previous_credit * -1, previous_credit = NULL WHERE temp_trial_balance2.previous_credit < 0;
        UPDATE temp_trial_balance2 SET previous_credit = temp_trial_balance2.previous_debit * -1, previous_debit = NULL WHERE temp_trial_balance2.previous_debit < 0;

        UPDATE temp_trial_balance2 SET debit = temp_trial_balance2.credit * -1, credit = NULL WHERE temp_trial_balance2.credit < 0;
        UPDATE temp_trial_balance2 SET credit = temp_trial_balance2.debit * -1, debit = NULL WHERE temp_trial_balance2.debit < 0;

        UPDATE temp_trial_balance2 SET closing_debit = temp_trial_balance2.closing_credit * -1, closing_credit = NULL WHERE temp_trial_balance2.closing_credit < 0;
        UPDATE temp_trial_balance2 SET closing_credit = temp_trial_balance2.closing_debit * -1, closing_debit = NULL WHERE temp_trial_balance2.closing_debit < 0;
    END IF;
    
    RETURN QUERY
    SELECT
        row_number() OVER(ORDER BY temp_trial_balance2.normally_debit DESC, temp_trial_balance2.account_id)::integer AS id,
        temp_trial_balance2.account_id,
        temp_trial_balance2.account_number,
        temp_trial_balance2.account,
        temp_trial_balance2.previous_debit,
        temp_trial_balance2.previous_credit,
        temp_trial_balance2.debit,
        temp_trial_balance2.credit,
        temp_trial_balance2.closing_debit,
        temp_trial_balance2.closing_credit
    FROM temp_trial_balance2;
END
$$
LANGUAGE plpgsql;

--SELECT * FROM finance.get_trial_balance('12-1-2014','12-31-2014',1,1, false, 1000, false, false);



-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_value_date.sql --<--<--
--DROP FUNCTION IF EXISTS finance.get_value_date(_office_id integer);

CREATE OR REPLACE FUNCTION finance.get_value_date(_office_id integer)
RETURNS date
AS
$$
    DECLARE this            RECORD;
    DECLARE _value_date     date;
BEGIN
    SELECT * FROM finance.day_operation
    WHERE office_id = _office_id
    AND value_date =
    (
        SELECT MAX(value_date)
        FROM finance.day_operation
        WHERE office_id = _office_id
    ) INTO this;

    IF(this.day_id IS NOT NULL) THEN
        IF(this.completed) THEN
            _value_date  := this.value_date + interval '1' day;
        ELSE
            _value_date  := this.value_date;    
        END IF;
    END IF;

    IF(_value_date IS NULL) THEN
        _value_date := NOW() AT time zone config.get_server_timezone();
    END IF;
    
    RETURN _value_date;
END
$$
LANGUAGE plpgsql;

--DROP FUNCTION IF EXISTS finance.get_month_end_date(_office_id integer);

CREATE OR REPLACE FUNCTION finance.get_month_end_date(_office_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN MIN(value_date) 
    FROM finance.frequency_setups
    WHERE value_date >= finance.get_value_date(_office_id)
    AND finance.frequency_setups.office_id = _office_id;
END
$$
LANGUAGE plpgsql;

--DROP FUNCTION IF EXISTS finance.get_month_start_date(_office_id integer);

CREATE OR REPLACE FUNCTION finance.get_month_start_date(_office_id integer)
RETURNS date
AS
$$
    DECLARE _date               date;
BEGIN
    SELECT MAX(value_date) + 1
    INTO _date
    FROM finance.frequency_setups
    WHERE value_date < 
    (
        SELECT MIN(value_date)
        FROM finance.frequency_setups
        WHERE value_date >= finance.get_value_date(_office_id)
        AND finance.frequency_setups.office_id = _office_id
    );

    IF(_date IS NULL) THEN
        SELECT starts_from 
        INTO _date
        FROM finance.fiscal_year
        WHERE finance.fiscal_year.office_id = _office_id;
    END IF;

    RETURN _date;
END
$$
LANGUAGE plpgsql;

--DROP FUNCTION IF EXISTS finance.get_quarter_end_date(_office_id integer);

CREATE OR REPLACE FUNCTION finance.get_quarter_end_date(_office_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN MIN(value_date) 
    FROM finance.frequency_setups
    WHERE value_date >= finance.get_value_date(_office_id)
    AND frequency_id > 2
    AND finance.frequency_setups.office_id = _office_id;
END
$$
LANGUAGE plpgsql;



--DROP FUNCTION IF EXISTS finance.get_quarter_start_date(_office_id integer);

CREATE OR REPLACE FUNCTION finance.get_quarter_start_date(_office_id integer)
RETURNS date
AS
$$
    DECLARE _date               date;
BEGIN
    SELECT MAX(value_date) + 1
    INTO _date
    FROM finance.frequency_setups
    WHERE value_date < 
    (
        SELECT MIN(value_date)
        FROM finance.frequency_setups
        WHERE value_date >= finance.get_value_date(_office_id)
        AND finance.frequency_setups.office_id = _office_id
    )
    AND frequency_id > 2;

    IF(_date IS NULL) THEN
        SELECT starts_from INTO _date
        FROM finance.fiscal_year
        WHERE finance.fiscal_year.office_id = _office_id;
    END IF;

    RETURN _date;
END
$$
LANGUAGE plpgsql;

--DROP FUNCTION IF EXISTS finance.get_fiscal_half_end_date(_office_id integer);

CREATE OR REPLACE FUNCTION finance.get_fiscal_half_end_date(_office_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN MIN(value_date) 
    FROM finance.frequency_setups
    WHERE value_date >= finance.get_value_date(_office_id)
    AND frequency_id > 3
    AND finance.frequency_setups.office_id = _office_id;
END
$$
LANGUAGE plpgsql;



--DROP FUNCTION IF EXISTS finance.get_fiscal_half_start_date(_office_id integer);

CREATE OR REPLACE FUNCTION finance.get_fiscal_half_start_date(_office_id integer)
RETURNS date
AS
$$
    DECLARE _date               date;
BEGIN
    SELECT MAX(value_date) + 1 INTO _date
    FROM finance.frequency_setups
    WHERE value_date < 
    (
        SELECT MIN(value_date)
        FROM finance.frequency_setups
        WHERE value_date >= finance.get_value_date(_office_id)
        AND finance.frequency_setups.office_id = _office_id
    )
    AND frequency_id > 3;

    IF(_date IS NULL) THEN
        SELECT starts_from INTO _date
        FROM finance.fiscal_year
        WHERE finance.fiscal_year.office_id = _office_id;
    END IF;

    RETURN _date;
END
$$
LANGUAGE plpgsql;


--DROP FUNCTION IF EXISTS finance.get_fiscal_year_end_date(_office_id integer);

CREATE OR REPLACE FUNCTION finance.get_fiscal_year_end_date(_office_id integer)
RETURNS date
AS
$$
BEGIN
    RETURN MIN(value_date) 
    FROM finance.frequency_setups
    WHERE value_date >= finance.get_value_date($1)
    AND frequency_id > 4
    AND finance.frequency_setups.office_id = _office_id;
END
$$
LANGUAGE plpgsql;



--DROP FUNCTION IF EXISTS finance.get_fiscal_year_start_date(_office_id integer);

CREATE OR REPLACE FUNCTION finance.get_fiscal_year_start_date(_office_id integer)
RETURNS date
AS
$$
    DECLARE _date               date;
BEGIN

    SELECT starts_from INTO _date
    FROM finance.fiscal_year
    WHERE finance.fiscal_year.office_id = _office_id;

    RETURN _date;
END
$$
LANGUAGE plpgsql;


--SELECT 1 AS office_id, finance.get_value_date(1::integer) AS today, finance.get_month_start_date(1::integer) AS month_start_date,finance.get_month_end_date(1::integer) AS month_end_date, finance.get_quarter_start_date(1::integer) AS quarter_start_date, finance.get_quarter_end_date(1::integer) AS quarter_end_date, finance.get_fiscal_half_start_date(1::integer) AS fiscal_half_start_date, finance.get_fiscal_half_end_date(1::integer) AS fiscal_half_end_date, finance.get_fiscal_year_start_date(1::integer) AS fiscal_year_start_date, finance.get_fiscal_year_end_date(1::integer) AS fiscal_year_end_date;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.get_verification_status_name_by_verification_status_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_verification_status_name_by_verification_status_id(_verification_status_id integer);

CREATE FUNCTION finance.get_verification_status_name_by_verification_status_id(_verification_status_id integer)
RETURNS text
AS
$$
BEGIN
    RETURN
        verification_status_name
    FROM finance.verification_statuses
    WHERE finance.verification_statuses.verification_status_id = _verification_status_id
	AND NOT finance.verification_statuses.deleted;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.has_child_accounts.sql --<--<--
DROP FUNCTION IF EXISTS finance.has_child_accounts(bigint);

CREATE FUNCTION finance.has_child_accounts(bigint)
RETURNS boolean
AS
$$
BEGIN
    IF EXISTS(SELECT 0 FROM finance.accounts WHERE parent_account_id=$1 LIMIT 1) THEN
        RETURN true;
    END IF;

    RETURN false;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.initialize_eod_operation.sql --<--<--
DROP FUNCTION IF EXISTS finance.initialize_eod_operation(_user_id integer, _office_id integer, _value_date date);

CREATE FUNCTION finance.initialize_eod_operation(_user_id integer, _office_id integer, _value_date date)
RETURNS void
AS
$$
    DECLARE this            RECORD;    
BEGIN
    IF(_value_date IS NULL) THEN
        RAISE EXCEPTION 'Invalid date.'
        USING ERRCODE='P3008';        
    END IF;

    IF(NOT account.is_admin(_user_id)) THEN
        RAISE EXCEPTION 'Access is denied.'
        USING ERRCODE='P9010';
    END IF;

    IF(_value_date != finance.get_value_date(_office_id)) THEN
        RAISE EXCEPTION 'Invalid value date.'
        USING ERRCODE='P3007';
    END IF;

    SELECT * FROM finance.day_operation
    WHERE value_date=_value_date 
    AND office_id = _office_id INTO this;

    IF(this IS NULL) THEN
        INSERT INTO finance.day_operation(office_id, value_date, started_on, started_by)
        SELECT _office_id, _value_date, NOW(), _user_id;
    ELSE    
        RAISE EXCEPTION 'EOD operation was already initialized.'
        USING ERRCODE='P8101';
    END IF;

    RETURN;
END
$$
LANGUAGE plpgsql;


--SELECT finance.initialize_eod_operation(1, 1, finance.get_value_date(1));
--delete from finance.day_operation

--select * from finance.day_operation


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.is_cash_account_id.sql --<--<--
DROP FUNCTION IF EXISTS finance.is_cash_account_id(_account_id bigint);

CREATE FUNCTION finance.is_cash_account_id(_account_id bigint)
RETURNS boolean
AS
$$
BEGIN
    IF EXISTS
    (
        SELECT 1 FROM finance.accounts 
        WHERE account_master_id IN(10101)
        AND account_id=_account_id
    ) THEN
        RETURN true;
    END IF;
    RETURN false;
END
$$
LANGUAGE plpgsql;




-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.is_eod_initialized.sql --<--<--
DROP FUNCTION IF EXISTS finance.is_eod_initialized(_office_id integer, _value_date date);

CREATE FUNCTION finance.is_eod_initialized(_office_id integer, _value_date date)
RETURNS boolean
AS
$$
BEGIN
    IF EXISTS
    (
        SELECT * FROM finance.day_operation
        WHERE office_id = _office_id
        AND value_date = _value_date
        AND completed = false
    ) then
        RETURN true;
    END IF;

    RETURN false;
END
$$
LANGUAGE plpgsql;


--SELECT * FROM finance.is_eod_initialized(1, '1-1-2000');

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.is_new_day_started.sql --<--<--
DROP FUNCTION IF EXISTS finance.is_new_day_started(_office_id integer);

CREATE or replace FUNCTION finance.is_new_day_started(_office_id integer)
RETURNS boolean
AS
$$
BEGIN
    IF EXISTS
    (
        SELECT 0 FROM finance.day_operation
        WHERE finance.day_operation.office_id = _office_id
        AND finance.day_operation.completed = false
        LIMIT 1
    ) THEN
        RETURN true;
    END IF;

    RETURN false;
END;
$$
LANGUAGE plpgsql;


--SELECT * FROM finance.is_new_day_started(1);

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.is_normally_debit.sql --<--<--
DROP FUNCTION IF EXISTS finance.is_normally_debit(_account_id bigint);

CREATE FUNCTION finance.is_normally_debit(_account_id bigint)
RETURNS boolean
AS
$$
BEGIN
    RETURN
        finance.account_masters.normally_debit
    FROM  finance.accounts
    INNER JOIN finance.account_masters
    ON finance.accounts.account_master_id = finance.account_masters.account_master_id
    WHERE finance.accounts.account_id = $1
	AND NOT finance.accounts.deleted;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.is_periodic_inventory.sql --<--<--
DROP FUNCTION IF EXISTS finance.is_periodic_inventory(_office_id integer);

CREATE FUNCTION finance.is_periodic_inventory(_office_id integer)
RETURNS boolean
AS
$$
BEGIN
    --Todo: parameterize
    RETURN false;
END
$$
LANGUAGE plpgsql;



-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.is_restricted_mode.sql --<--<--
DROP FUNCTION IF EXISTS finance.is_restricted_mode();

CREATE FUNCTION finance.is_restricted_mode()
RETURNS boolean
AS
$$
BEGIN
    IF EXISTS
    (
        SELECT 0 FROM finance.day_operation
        WHERE completed = false
        LIMIT 1
    ) THEN
        RETURN true;
    END IF;

    RETURN false;
END;
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.is_transaction_restricted.sql --<--<--
DROP FUNCTION IF EXISTS finance.is_transaction_restricted
(
    _office_id      integer
);

CREATE FUNCTION finance.is_transaction_restricted
(
    _office_id      integer
)
RETURNS boolean
STABLE
AS
$$
BEGIN
    RETURN NOT allow_transaction_posting
    FROM core.offices
    WHERE office_id=$1;
END
$$
LANGUAGE plpgsql;


--SELECT * FROM finance.is_transaction_restricted(1);

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.perform_eod_operation.sql --<--<--
DROP FUNCTION IF EXISTS finance.perform_eod_operation(_user_id integer, _login_id bigint, _office_id integer, _value_date date);

CREATE OR REPLACE FUNCTION finance.perform_eod_operation(_user_id integer, _login_id bigint, _office_id integer, _value_date date)
RETURNS boolean 
AS
$$
    DECLARE _routine            regproc;
    DECLARE _routine_id         integer;
    DECLARE this                RECORD;
    DECLARE _sql                text;
    DECLARE _is_error           boolean=false;
    DECLARE _notice             text;
    DECLARE _office_code        text;
BEGIN
    IF(_value_date IS NULL) THEN
        RAISE EXCEPTION 'Invalid date.'
        USING ERRCODE='P3008';
    END IF;

    IF(NOT account.is_admin(_user_id)) THEN
        RAISE EXCEPTION 'Access is denied.'
        USING ERRCODE='P9001';
    END IF;

    IF(_value_date != finance.get_value_date(_office_id)) THEN
        RAISE EXCEPTION 'Invalid value date.'
        USING ERRCODE='P3007';
    END IF;

    SELECT * FROM finance.day_operation
    WHERE value_date=_value_date 
    AND office_id = _office_id INTO this;

    IF(this IS NULL) THEN
        RAISE EXCEPTION 'Invalid value date.'
        USING ERRCODE='P3007';
    ELSE    
        IF(this.completed OR this.completed_on IS NOT NULL) THEN
            RAISE EXCEPTION 'End of day operation was already performed.'
            USING ERRCODE='P5102';
            _is_error        := true;
        END IF;
    END IF;

    IF EXISTS
    (
        SELECT * FROM finance.transaction_master
        WHERE value_date < _value_date
        AND verification_status_id = 0
    ) THEN
        RAISE EXCEPTION 'Past dated transactions in verification queue.'
        USING ERRCODE='P5103';
        _is_error        := true;
    END IF;

    IF EXISTS
    (
        SELECT * FROM finance.transaction_master
        WHERE value_date = _value_date
        AND verification_status_id = 0
    ) THEN
        RAISE EXCEPTION 'Please verify transactions before performing end of day operation.'
        USING ERRCODE='P5104';
        _is_error        := true;
    END IF;
    
    IF(NOT _is_error) THEN
        _office_code        := core.get_office_code_by_office_id(_office_id);
        _notice             := 'EOD started.'::text;
        RAISE INFO  '%', _notice;

        FOR this IN
        SELECT routine_id, routine_name 
        FROM finance.routines 
        WHERE status 
        ORDER BY "order" ASC
        LOOP
            _routine_id             := this.routine_id;
            _routine                := this.routine_name;
            _sql                    := format('SELECT * FROM %1$s($1, $2, $3, $4);', _routine);

            RAISE NOTICE '%', _sql;

            _notice             := 'Performing ' || _routine::text || '.';
            RAISE INFO '%', _notice;

            PERFORM pg_sleep(5);
            EXECUTE _sql USING _user_id, _login_id, _office_id, _value_date;

            _notice             := 'Completed  ' || _routine::text || '.';
            RAISE INFO '%', _notice;
            
            PERFORM pg_sleep(5);            
        END LOOP;


        UPDATE finance.day_operation SET 
            completed_on = NOW(), 
            completed_by = _user_id,
            completed = true
        WHERE value_date=_value_date
        AND office_id = _office_id;

        _notice             := 'EOD of ' || _office_code || ' for ' || _value_date::text || ' completed without errors.'::text;
        RAISE INFO '%', _notice;

        _notice             := 'OK'::text;
        RAISE INFO '%', _notice;

        RETURN true;
    END IF;

    RETURN false;    
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION finance.perform_eod_operation(_login_id bigint)
RETURNS boolean 
AS
$$
    DECLARE _user_id    integer;
    DECLARE _office_id integer;
    DECLARE _value_date date;
BEGIN
    SELECT 
        user_id,
        office_id,
        finance.get_value_date(office_id)
    INTO
        _user_id,
        _office_id,
        _value_date
    FROM account.logins
    WHERE login_id=_login_id;

    RETURN finance.perform_eod_operation(_user_id,_login_id, _office_id, _value_date);
END
$$
LANGUAGE plpgsql;


--SELECT * FROM finance.perform_eod_operation(1, 1, 1, finance.get_value_date(1));


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/finance.verify_transaction.sql --<--<--
DROP FUNCTION IF EXISTS finance.verify_transaction
(
    _transaction_master_id                  bigint,
    _office_id                              integer,
    _user_id                                integer,
    _login_id                               bigint,
    _verification_status_id                 smallint,
    _reason                                 national character varying
) 
CASCADE;

CREATE FUNCTION finance.verify_transaction
(
    _transaction_master_id                  bigint,
    _office_id                              integer,
    _user_id                                integer,
    _login_id                               bigint,
    _verification_status_id                 smallint,
    _reason                                 national character varying
)
RETURNS bigint
VOLATILE
AS
$$
    DECLARE _transaction_posted_by          integer;
    DECLARE _book                           text;
    DECLARE _can_verify                     boolean;
    DECLARE _verification_limit             public.money_strict2;
    DECLARE _can_self_verify                boolean;
    DECLARE _self_verification_limit        public.money_strict2;
    DECLARE _posted_amount                  public.money_strict2;
    DECLARE _has_policy                     boolean=false;
    DECLARE _journal_date                   date;
    DECLARE _journal_office_id              integer;
    DECLARE _cascading_tran_id              bigint;
BEGIN

    SELECT
        finance.transaction_master.book,
        finance.transaction_master.value_date,
        finance.transaction_master.office_id,
        finance.transaction_master.user_id
    INTO
        _book,
        _journal_date,
        _journal_office_id,
        _transaction_posted_by  
    FROM
    finance.transaction_master
    WHERE finance.transaction_master.transaction_master_id=_transaction_master_id
	AND NOT finance.transaction_master.deleted;


    IF(_journal_office_id <> _office_id) THEN
        RAISE EXCEPTION 'Access is denied. You cannot verify a transaction of another office.'
        USING ERRCODE='P9014';
    END IF;
        
    SELECT
        SUM(amount_in_local_currency)
    INTO
        _posted_amount
    FROM finance.transaction_details
    WHERE finance.transaction_details.transaction_master_id = _transaction_master_id
    AND finance.transaction_details.tran_type='Cr';


    SELECT
        true,
        can_verify,
        verification_limit,
        can_self_verify,
        self_verification_limit
    INTO
        _has_policy,
        _can_verify,
        _verification_limit,
        _can_self_verify,
        _self_verification_limit
    FROM finance.journal_verification_policy
    WHERE finance.journal_verification_policy.user_id=_user_id
    AND finance.journal_verification_policy.office_id = _office_id
    AND finance.journal_verification_policy.is_active=true
    AND now() >= effective_from
    AND now() <= ends_on
	AND NOT finance.journal_verification_policy.deleted;

    IF(NOT _can_self_verify AND _user_id = _transaction_posted_by) THEN
        _can_verify := false;
    END IF;

    IF(_has_policy) THEN
        IF(_can_verify) THEN
        
            SELECT cascading_tran_id
            INTO _cascading_tran_id
            FROM finance.transaction_master
            WHERE finance.transaction_master.transaction_master_id=_transaction_master_id
			AND NOT finance.transaction_master.deleted;
            
            UPDATE finance.transaction_master
            SET 
                last_verified_on = now(),
                verified_by_user_id=_user_id,
                verification_status_id=_verification_status_id,
                verification_reason=_reason
            WHERE
                finance.transaction_master.transaction_master_id=_transaction_master_id
            OR 
                finance.transaction_master.cascading_tran_id =_transaction_master_id
            OR
            finance.transaction_master.transaction_master_id = _cascading_tran_id;

            RAISE NOTICE 'Done.';

            IF(COALESCE(_cascading_tran_id, 0) = 0) THEN
                SELECT transaction_master_id
                INTO _cascading_tran_id
                FROM finance.transaction_master
                WHERE finance.transaction_master.cascading_tran_id=_transaction_master_id
				AND NOT finance.transaction_master.deleted;
            END IF;
            
            RETURN COALESCE(_cascading_tran_id, 0);
        ELSE
            RAISE EXCEPTION 'Please ask someone else to verify your transaction.'
            USING ERRCODE='P4031';
        END IF;
    ELSE
        RAISE EXCEPTION 'No verification policy found for this user.'
        USING ERRCODE='P4030';
    END IF;

    RETURN 0;
END
$$
LANGUAGE plpgsql;

--SELECT * FROM finance.verify_transaction(1::bigint, 1, 1, 6::bigint, 2::smallint, 'OK');

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/logic/finance.create_payment_card.sql --<--<--
DROP FUNCTION IF EXISTS finance.create_payment_card
(
    _payment_card_code      national character varying(12),
    _payment_card_name      national character varying(100),
    _card_type_id           integer
);

CREATE FUNCTION finance.create_payment_card
(
    _payment_card_code      national character varying(12),
    _payment_card_name      national character varying(100),
    _card_type_id           integer
)
RETURNS void
AS
$$
BEGIN
    IF NOT EXISTS
    (
        SELECT * FROM finance.payment_cards
        WHERE payment_card_code = _payment_card_code
    ) THEN
        INSERT INTO finance.payment_cards(payment_card_code, payment_card_name, card_type_id)
        SELECT _payment_card_code, _payment_card_name, _card_type_id;
    ELSE
        UPDATE finance.payment_cards
        SET 
            payment_card_code =     _payment_card_code, 
            payment_card_name =     _payment_card_name,
            card_type_id =          _card_type_id
        WHERE
            payment_card_code =     _payment_card_code;
    END IF;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/logic/finance.get_balance_sheet.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_balance_sheet
(
    _previous_period                date,
    _current_period                 date,
    _user_id                        integer,
    _office_id                      integer,
    _factor                         integer
);

CREATE FUNCTION finance.get_balance_sheet
(
    _previous_period                date,
    _current_period                 date,
    _user_id                        integer,
    _office_id                      integer,
    _factor                         integer
)
RETURNS TABLE
(
    id                              bigint,
    item                            text,
    previous_period                 decimal(24, 4),
    current_period                  decimal(24, 4),
    account_id                      integer,
    account_number                  text,
    is_retained_earning             boolean
)
AS
$$
    DECLARE this                    RECORD;
    DECLARE _date_from              date;
BEGIN
    _date_from := finance.get_fiscal_year_start_date(_office_id);

    IF(COALESCE(_factor, 0) = 0) THEN
        _factor := 1;
    END IF;

    DROP TABLE IF EXISTS bs_temp;
    CREATE TEMPORARY TABLE bs_temp
    (
        item_id                     int PRIMARY KEY,
        item                        text,
        account_number              text,
        account_id                  integer,
        child_accounts              integer[],
        parent_item_id              integer REFERENCES bs_temp(item_id),
        is_debit                    boolean DEFAULT(false),
        previous_period             decimal(24, 4) DEFAULT(0),
        current_period              decimal(24, 4) DEFAULT(0),
        sort                        int,
        skip                        boolean DEFAULT(false),
        is_retained_earning         boolean DEFAULT(false)
    ) ON COMMIT DROP;
    
    --BS structure setup start
    INSERT INTO bs_temp(item_id, item, parent_item_id)
    SELECT  1,       'Assets',                              NULL::numeric   UNION ALL
    SELECT  10100,   'Current Assets',                      1               UNION ALL
    SELECT  10101,   'Cash A/C',                            1               UNION ALL
    SELECT  10102,   'Bank A/C',                            1               UNION ALL
    SELECT  10110,   'Accounts Receivable',                 10100           UNION ALL
    SELECT  10200,   'Fixed Assets',                        1               UNION ALL
    SELECT  10201,   'Property, Plants, and Equipments',    10201           UNION ALL
    SELECT  10300,   'Other Assets',                        1               UNION ALL
    SELECT  14900,   'Liabilities & Shareholders'' Equity', NULL            UNION ALL
    SELECT  15000,   'Current Liabilities',                 14900           UNION ALL
    SELECT  15010,   'Accounts Payable',                    15000           UNION ALL
    SELECT  15011,   'Salary Payable',                      15000           UNION ALL
    SELECT  15100,   'Long-Term Liabilities',               14900           UNION ALL
    SELECT  15200,   'Shareholders'' Equity',               14900           UNION ALL
    SELECT  15300,   'Retained Earnings',                   15200;

    UPDATE bs_temp SET is_debit = true WHERE bs_temp.item_id <= 10300;
    UPDATE bs_temp SET is_retained_earning = true WHERE bs_temp.item_id = 15300;
    
    INSERT INTO bs_temp(item_id, account_id, account_number, parent_item_id, item, is_debit, child_accounts)
    SELECT 
        row_number() OVER(ORDER BY finance.accounts.account_master_id) + (finance.accounts.account_master_id * 100) AS id,
        finance.accounts.account_id,
        finance.accounts.account_number,
        finance.accounts.account_master_id,
        finance.accounts.account_name,
        finance.account_masters.normally_debit,
        array_agg(agg)
    FROM finance.accounts
    INNER JOIN finance.account_masters
    ON finance.accounts.account_master_id = finance.account_masters.account_master_id,
    finance.get_account_ids(finance.accounts.account_id) as agg
    WHERE parent_account_id IN
    (
        SELECT finance.accounts.account_id
        FROM finance.accounts
        WHERE finance.accounts.sys_type
        AND finance.accounts.account_master_id BETWEEN 10100 AND 15200
    )
    AND finance.accounts.account_master_id BETWEEN 10100 AND 15200
    GROUP BY finance.accounts.account_id, finance.account_masters.normally_debit
    ORDER BY account_master_id;


    --Updating credit balances of individual GL accounts.
    UPDATE bs_temp SET previous_period = tran.previous_period
    FROM
    (
        SELECT 
            bs_temp.account_id,         
            SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END) AS previous_period
        FROM bs_temp
        INNER JOIN finance.verified_transaction_mat_view
        ON finance.verified_transaction_mat_view.account_id = ANY(bs_temp.child_accounts)
        WHERE value_date <=_previous_period
        AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        GROUP BY bs_temp.account_id
    ) AS tran
    WHERE bs_temp.account_id = tran.account_id;

    --Updating credit balances of individual GL accounts.
    UPDATE bs_temp SET current_period = tran.current_period
    FROM
    (
        SELECT 
            bs_temp.account_id,         
            SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END) AS current_period
        FROM bs_temp
        INNER JOIN finance.verified_transaction_mat_view
        ON finance.verified_transaction_mat_view.account_id = ANY(bs_temp.child_accounts)
        WHERE value_date <=_current_period
        AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        GROUP BY bs_temp.account_id
    ) AS tran
    WHERE bs_temp.account_id = tran.account_id;


    --Dividing by the factor.
    UPDATE bs_temp SET 
        previous_period = bs_temp.previous_period / _factor,
        current_period = bs_temp.current_period / _factor;

    --Upading balance of retained earnings
    UPDATE bs_temp SET 
        previous_period = finance.get_retained_earnings(_previous_period, _office_id, _factor),
        current_period = finance.get_retained_earnings(_current_period, _office_id, _factor)
    WHERE bs_temp.item_id = 15300;

    --Reversing assets to debit balance.
    UPDATE bs_temp SET 
        previous_period=bs_temp.previous_period*-1,
        current_period=bs_temp.current_period*-1 
    WHERE bs_temp.is_debit;



    FOR this IN 
    SELECT * FROM bs_temp 
    WHERE COALESCE(bs_temp.previous_period, 0) + COALESCE(bs_temp.current_period, 0) != 0 
    AND bs_temp.account_id IS NOT NULL
    LOOP
        UPDATE bs_temp SET skip = true WHERE this.account_id = ANY(bs_temp.child_accounts)
        AND bs_temp.account_id != this.account_id;
    END LOOP;

    --Updating current period amount on GL parent item by the sum of their respective child balances.
    WITH running_totals AS
    (
        SELECT bs_temp.parent_item_id,
        SUM(COALESCE(bs_temp.previous_period, 0)) AS previous_period,
        SUM(COALESCE(bs_temp.current_period, 0)) AS current_period
        FROM bs_temp
        WHERE NOT skip
        AND parent_item_id IS NOT NULL
        GROUP BY bs_temp.parent_item_id
    )
    UPDATE bs_temp SET 
        previous_period = running_totals.previous_period,
        current_period = running_totals.current_period
    FROM running_totals
    WHERE running_totals.parent_item_id = bs_temp.item_id
    AND bs_temp.item_id
    IN
    (
        SELECT parent_item_id FROM running_totals
    );


    --Updating sum amount on parent item by the sum of their respective child balances.
    UPDATE bs_temp SET 
        previous_period = tran.previous_period,
        current_period = tran.current_period
    FROM 
    (
        SELECT bs_temp.parent_item_id,
        SUM(bs_temp.previous_period) AS previous_period,
        SUM(bs_temp.current_period) AS current_period
        FROM bs_temp
        WHERE bs_temp.parent_item_id IS NOT NULL
        GROUP BY bs_temp.parent_item_id
    ) 
    AS tran 
    WHERE tran.parent_item_id = bs_temp.item_id
    AND tran.parent_item_id IS NOT NULL;


    --Updating sum amount on grandparents.
    UPDATE bs_temp SET 
        previous_period = tran.previous_period,
        current_period = tran.current_period
    FROM 
    (
        SELECT bs_temp.parent_item_id,
        SUM(bs_temp.previous_period) AS previous_period,
        SUM(bs_temp.current_period) AS current_period
        FROM bs_temp
        WHERE bs_temp.parent_item_id IS NOT NULL
        GROUP BY bs_temp.parent_item_id
    ) 
    AS tran 
    WHERE tran.parent_item_id = bs_temp.item_id;

    --Removing ledgers having zero balances
    DELETE FROM bs_temp
    WHERE COALESCE(bs_temp.previous_period, 0) + COALESCE(bs_temp.current_period, 0) = 0
    AND bs_temp.account_id IS NOT NULL;

    --Converting 0's to NULLS.
    UPDATE bs_temp SET previous_period = CASE WHEN bs_temp.previous_period = 0 THEN NULL ELSE bs_temp.previous_period END;
    UPDATE bs_temp SET current_period = CASE WHEN bs_temp.current_period = 0 THEN NULL ELSE bs_temp.current_period END;
    
    UPDATE bs_temp SET sort = bs_temp.item_id WHERE bs_temp.item_id < 15400;
    UPDATE bs_temp SET sort = bs_temp.parent_item_id WHERE bs_temp.item_id >= 15400;

    RETURN QUERY
    SELECT
        row_number() OVER(order by bs_temp.sort, bs_temp.item_id) AS id,
        bs_temp.item,
        bs_temp.previous_period,
        bs_temp.current_period,
        bs_temp.account_id,
        bs_temp.account_number,
        bs_temp.is_retained_earning
    FROM bs_temp;
END;
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/logic/finance.get_cash_flow_statement.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_cash_flow_statement
(
    _date_from                      date,
    _date_to                        date,
    _user_id                        integer,
    _office_id                      integer,
    _factor                         integer
);

CREATE FUNCTION finance.get_cash_flow_statement
(
    _date_from                      date,
    _date_to                        date,
    _user_id                        integer,
    _office_id                      integer,
    _factor                         integer
)
RETURNS json
AS
$$
    DECLARE _sql                    text;
    DECLARE _periods                finance.period[];
    DECLARE _json                   json;
    DECLARE this                    RECORD;
    DECLARE _balance                decimal(24, 4);
    DECLARE _is_periodic            boolean = finance.is_periodic_inventory(_office_id);
BEGIN    
    --We cannot divide by zero.
    IF(COALESCE(_factor, 0) = 0) THEN
        _factor := 1;
    END IF;

    DROP TABLE IF EXISTS cf_temp;
    CREATE TEMPORARY TABLE cf_temp
    (
        item_id                     integer PRIMARY KEY,
        item                        text,
        account_master_id           integer,
        parent_item_id              integer REFERENCES cf_temp(item_id),
        is_summation                boolean DEFAULT(false),
        is_debit                    boolean DEFAULT(false),
        is_sales                    boolean DEFAULT(false),
        is_purchase                 boolean DEFAULT(false)
    ) ON COMMIT DROP;


    _periods            := finance.get_periods(_date_from, _date_to);

    IF(_periods IS NULL) THEN
        RAISE EXCEPTION 'Invalid period specified.'
        USING ERRCODE='P3009';
    END IF;

    /**************************************************************************************************************************************************************************************
        CREATING PERIODS
    **************************************************************************************************************************************************************************************/
    SELECT string_agg(dynamic, '') FROM
    (
            SELECT 'ALTER TABLE cf_temp ADD COLUMN "' || period_name || '" decimal(24, 4) DEFAULT(0);' as dynamic
            FROM explode_array(_periods)
         
    ) periods
    INTO _sql;
    
    EXECUTE _sql;

    /**************************************************************************************************************************************************************************************
        CASHFLOW TABLE STRUCTURE START
    **************************************************************************************************************************************************************************************/
    INSERT INTO cf_temp(item_id, item, is_summation, is_debit)
    SELECT  10000,  'Cash and cash equivalents, beginning of period',   false,  true    UNION ALL    
    SELECT  20000,  'Cash flows from operating activities',             true,   false   UNION ALL    
    SELECT  30000,  'Cash flows from investing activities',             true,   false   UNION ALL
    SELECT  40000,  'Cash flows from financing acticities',             true,   false   UNION ALL    
    SELECT  50000,  'Net increase in cash and cash equivalents',        false,  false   UNION ALL    
    SELECT  60000,  'Cash and cash equivalents, end of period',         false,  true;    

    INSERT INTO cf_temp(item_id, item, parent_item_id, is_debit, is_sales, is_purchase)
    SELECT  cash_flow_heading_id,   cash_flow_heading_name, 20000,  is_debit,   is_sales,   is_purchase FROM core.cash_flow_headings WHERE cash_flow_heading_type = 'O' UNION ALL
    SELECT  cash_flow_heading_id,   cash_flow_heading_name, 30000,  is_debit,   is_sales,   is_purchase FROM core.cash_flow_headings WHERE cash_flow_heading_type = 'I' UNION ALL 
    SELECT  cash_flow_heading_id,   cash_flow_heading_name, 40000,  is_debit,   is_sales,   is_purchase FROM core.cash_flow_headings WHERE cash_flow_heading_type = 'F';

    INSERT INTO cf_temp(item_id, item, parent_item_id, is_debit, account_master_id)
    SELECT core.account_masters.account_master_id + 50000, core.account_masters.account_master_name,  core.cash_flow_setup.cash_flow_heading_id, core.cash_flow_headings.is_debit, core.account_masters.account_master_id
    FROM core.cash_flow_setup
    INNER JOIN core.account_masters
    ON core.cash_flow_setup.account_master_id = core.account_masters.account_master_id
    INNER JOIN core.cash_flow_headings
    ON core.cash_flow_setup.cash_flow_heading_id = core.cash_flow_headings.cash_flow_heading_id;

    /**************************************************************************************************************************************************************************************
        CASHFLOW TABLE STRUCTURE END
    **************************************************************************************************************************************************************************************/


    /**************************************************************************************************************************************************************************************
        ITERATING THROUGH PERIODS TO UPDATE TRANSACTION BALANCES
    **************************************************************************************************************************************************************************************/
    FOR this IN SELECT * FROM explode_array(_periods) ORDER BY date_from ASC
    LOOP
        --
        --
        --Opening cash balance.
        --
        --
        _sql := 'UPDATE cf_temp SET "' || this.period_name || '"=
            (
                SELECT
                SUM(CASE tran_type WHEN ''Cr'' THEN amount_in_local_currency ELSE 0 END) - 
                SUM(CASE tran_type WHEN ''Dr'' THEN amount_in_local_currency ELSE 0 END) AS total_amount
            FROM finance.verified_cash_transaction_mat_view
            WHERE account_master_id IN(10101, 10102) 
            AND value_date <''' || this.date_from::text ||
            ''' AND office_id IN (SELECT * FROM core.get_office_ids(' || _office_id::text || '))
            )
        WHERE cf_temp.item_id = 10000;';

        EXECUTE _sql;

        --
        --
        --Updating debit balances of mapped account master heads.
        --
        --
        _sql := 'UPDATE cf_temp SET "' || this.period_name || '"=tran.total_amount
        FROM
        (
            SELECT finance.verified_cash_transaction_mat_view.account_master_id,
            SUM(CASE tran_type WHEN ''Dr'' THEN amount_in_local_currency ELSE 0 END) - 
            SUM(CASE tran_type WHEN ''Cr'' THEN amount_in_local_currency ELSE 0 END) AS total_amount
        FROM finance.verified_cash_transaction_mat_view
        WHERE finance.verified_cash_transaction_mat_view.book NOT IN (''Sales.Direct'', ''Sales.Receipt'', ''Sales.Delivery'', ''Purchase.Direct'', ''Purchase.Receipt'')
        AND NOT account_master_id IN(10101, 10102) 
        AND value_date >=''' || this.date_from::text || ''' AND value_date <=''' || this.date_to::text ||
        ''' AND office_id IN (SELECT * FROM core.get_office_ids(' || _office_id::text || '))
        GROUP BY finance.verified_cash_transaction_mat_view.account_master_id
        ) AS tran
        WHERE tran.account_master_id = cf_temp.account_master_id';
        EXECUTE _sql;

        --
        --
        --Updating cash paid to suppliers.
        --
        --
        _sql := 'UPDATE cf_temp SET "' || this.period_name || '"=
        
        (
            SELECT
            SUM(CASE tran_type WHEN ''Dr'' THEN amount_in_local_currency ELSE 0 END) - 
            SUM(CASE tran_type WHEN ''Cr'' THEN amount_in_local_currency ELSE 0 END) 
        FROM finance.verified_cash_transaction_mat_view
        WHERE finance.verified_cash_transaction_mat_view.book IN (''Purchase.Direct'', ''Purchase.Receipt'', ''Purchase.Payment'')
        AND NOT account_master_id IN(10101, 10102) 
        AND value_date >=''' || this.date_from::text || ''' AND value_date <=''' || this.date_to::text ||
        ''' AND office_id IN (SELECT * FROM core.get_office_ids(' || _office_id::text || '))
        )
        WHERE cf_temp.is_purchase;';
        EXECUTE _sql;

        --
        --
        --Updating cash received from customers.
        --
        --
        _sql := 'UPDATE cf_temp SET "' || this.period_name || '"=
        
        (
            SELECT
            SUM(CASE tran_type WHEN ''Cr'' THEN amount_in_local_currency ELSE 0 END) - 
            SUM(CASE tran_type WHEN ''Dr'' THEN amount_in_local_currency ELSE 0 END) 
        FROM finance.verified_cash_transaction_mat_view
        WHERE finance.verified_cash_transaction_mat_view.book IN (''Sales.Direct'', ''Sales.Receipt'', ''Sales.Delivery'')
        AND account_master_id IN(10101, 10102) 
        AND value_date >=''' || this.date_from::text || ''' AND value_date <=''' || this.date_to::text ||
        ''' AND office_id IN (SELECT * FROM core.get_office_ids(' || _office_id::text || '))
        )
        WHERE cf_temp.is_sales;';
        RAISE NOTICE '%', _SQL;
        EXECUTE _sql;

        --Closing cash balance.
        _sql := 'UPDATE cf_temp SET "' || this.period_name || '"
        =
        (
            SELECT
            SUM(CASE tran_type WHEN ''Cr'' THEN amount_in_local_currency ELSE 0 END) - 
            SUM(CASE tran_type WHEN ''Dr'' THEN amount_in_local_currency ELSE 0 END) AS total_amount
        FROM finance.verified_cash_transaction_mat_view
        WHERE account_master_id IN(10101, 10102) 
        AND value_date <''' || this.date_to::text ||
        ''' AND office_id IN (SELECT * FROM core.get_office_ids(' || _office_id::text || '))
        ) 
        WHERE cf_temp.item_id = 60000;';

        EXECUTE _sql;

        --Reversing to debit balance for associated headings.
        _sql := 'UPDATE cf_temp SET "' || this.period_name || '"="' || this.period_name || '"*-1 WHERE is_debit=true;';
        EXECUTE _sql;
    END LOOP;



    --Updating periodic balances on parent item by the sum of their respective child balances.
    SELECT 'UPDATE cf_temp SET ' || array_to_string(array_agg('"' || period_name || '"' || '=cf_temp."' || period_name || '" + tran."' || period_name || '"'), ',') || 
    ' FROM 
    (
        SELECT parent_item_id, '
        || array_to_string(array_agg('SUM("' || period_name || '") AS "' || period_name || '"'), ',') || '
         FROM cf_temp
        GROUP BY parent_item_id
    ) 
    AS tran
        WHERE tran.parent_item_id = cf_temp.item_id
        AND cf_temp.item_id NOT IN (10000, 60000);'
    INTO _sql
    FROM explode_array(_periods);

        RAISE NOTICE '%', _SQL;
    EXECUTE _sql;


    SELECT 'UPDATE cf_temp SET ' || array_to_string(array_agg('"' || period_name || '"=tran."' || period_name || '"'), ',') 
    || ' FROM 
    (
        SELECT
            cf_temp.parent_item_id,'
        || array_to_string(array_agg('SUM(CASE is_debit WHEN true THEN "' || period_name || '" ELSE "' || period_name || '" *-1 END) AS "' || period_name || '"'), ',') ||
    '
         FROM cf_temp
         GROUP BY cf_temp.parent_item_id
    ) 
    AS tran
    WHERE cf_temp.item_id = tran.parent_item_id
    AND cf_temp.parent_item_id IS NULL;'
    INTO _sql
    FROM explode_array(_periods);

    EXECUTE _sql;


    --Dividing by the factor.
    SELECT 'UPDATE cf_temp SET ' || array_to_string(array_agg('"' || period_name || '"="' || period_name || '"/' || _factor::text), ',') || ';'
    INTO _sql
    FROM explode_array(_periods);
    EXECUTE _sql;


    --Converting 0's to NULLS.
    SELECT 'UPDATE cf_temp SET ' || array_to_string(array_agg('"' || period_name || '"= CASE WHEN "' || period_name || '" = 0 THEN NULL ELSE "' || period_name || '" END'), ',') || ';'
    INTO _sql
    FROM explode_array(_periods);

    EXECUTE _sql;

    SELECT 
    'SELECT array_to_json(array_agg(row_to_json(report)))
    FROM
    (
        SELECT item, '
        || array_to_string(array_agg('"' || period_name || '"'), ',') ||
        ', is_summation FROM cf_temp
        WHERE account_master_id IS NULL
        ORDER BY item_id
    ) AS report;'
    INTO _sql
    FROM explode_array(_periods);

    EXECUTE _sql INTO _json ;

    RETURN _json;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/logic/finance.get_net_profit.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_net_profit
(
    _date_from                      date,
    _date_to                        date,
    _office_id                      integer,
    _factor                         integer,
    _no_provison                    boolean
);

CREATE FUNCTION finance.get_net_profit
(
    _date_from                      date,
    _date_to                        date,
    _office_id                      integer,
    _factor                         integer,
    _no_provison                    boolean DEFAULT false
)
RETURNS decimal(24, 4)
AS
$$
    DECLARE _incomes                decimal(24, 4) = 0;
    DECLARE _expenses               decimal(24, 4) = 0;
    DECLARE _profit_before_tax      decimal(24, 4) = 0;
    DECLARE _tax_paid               decimal(24, 4) = 0;
    DECLARE _tax_provison           decimal(24, 4) = 0;
BEGIN
    SELECT SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END)
    INTO _incomes
    FROM finance.verified_transaction_mat_view
    WHERE value_date >= _date_from AND value_date <= _date_to
    AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
    AND account_master_id >=20100
    AND account_master_id <= 20300;
    
    SELECT SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END)
    INTO _expenses
    FROM finance.verified_transaction_mat_view
    WHERE value_date >= _date_from AND value_date <= _date_to
    AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
    AND account_master_id >=20400
    AND account_master_id <= 20701;
    
    SELECT SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END)
    INTO _tax_paid
    FROM finance.verified_transaction_mat_view
    WHERE value_date >= _date_from AND value_date <= _date_to
    AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
    AND account_master_id =20800;
    
    _profit_before_tax := COALESCE(_incomes, 0) - COALESCE(_expenses, 0);

    IF(_no_provison) THEN
        RETURN (_profit_before_tax - COALESCE(_tax_paid, 0)) / _factor;
    END IF;
    
    _tax_provison      := core.get_income_tax_provison_amount(_office_id, _profit_before_tax, COALESCE(_tax_paid, 0));
    
    RETURN (_profit_before_tax - (COALESCE(_tax_provison, 0) + COALESCE(_tax_paid, 0))) / _factor;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/logic/finance.get_profit_and_loss_statement.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_profit_and_loss_statement
(
    _date_from                      date,
    _date_to                        date,
    _user_id                        integer,
    _office_id                      integer,
    _factor                         integer,
    _compact                        boolean
);

CREATE FUNCTION finance.get_profit_and_loss_statement
(
    _date_from                      date,
    _date_to                        date,
    _user_id                        integer,
    _office_id                      integer,
    _factor                         integer,
    _compact                        boolean DEFAULT(true)
)
RETURNS json
AS
$$
    DECLARE _sql                    text;
    DECLARE _periods                finance.period[];
    DECLARE _json                   json;
    DECLARE this                    RECORD;
    DECLARE _balance                decimal(24, 4);
    DECLARE _is_periodic            boolean = finance.is_periodic_inventory(_office_id);
BEGIN    
    DROP TABLE IF EXISTS pl_temp;
    CREATE TEMPORARY TABLE pl_temp
    (
        item_id                     integer PRIMARY KEY,
        item                        text,
        account_id                  integer,
        parent_item_id              integer REFERENCES pl_temp(item_id),
        is_profit                   boolean DEFAULT(false),
        is_summation                boolean DEFAULT(false),
        is_debit                    boolean DEFAULT(false),
        amount                      decimal(24, 4) DEFAULT(0)
    ) ON COMMIT DROP;

    IF(COALESCE(_factor, 0) = 0) THEN
        _factor := 1;
    END IF;

    _periods            := finance.get_periods(_date_from, _date_to);

    IF(_periods IS NULL) THEN
        RAISE EXCEPTION 'Invalid period specified.'
        USING ERRCODE='P3009';
    END IF;

    SELECT string_agg(dynamic, '') FROM
    (
            SELECT 'ALTER TABLE pl_temp ADD COLUMN "' || period_name || '" decimal(24, 4) DEFAULT(0);' as dynamic
            FROM explode_array(_periods)
         
    ) periods
    INTO _sql;
    
    EXECUTE _sql;

    --PL structure setup start
    INSERT INTO pl_temp(item_id, item, is_summation, parent_item_id)
    SELECT 1000,   'Revenue',                      true,   NULL::integer   UNION ALL
    SELECT 2000,   'Cost of Sales',                true,   NULL::integer   UNION ALL
    SELECT 2001,   'Opening Stock',                false,  1000            UNION ALL
    SELECT 3000,   'Purchases',                    false,  1000            UNION ALL
    SELECT 4000,   'Closing Stock',                false,  1000            UNION ALL
    SELECT 5000,   'Direct Costs',                 true,   NULL::integer   UNION ALL
    SELECT 6000,   'Gross Profit',                 false,  NULL::integer   UNION ALL
    SELECT 7000,   'Operating Expenses',           true,   NULL::integer   UNION ALL
    SELECT 8000,   'Operating Profit',             false,  NULL::integer   UNION ALL
    SELECT 9000,   'Nonoperating Incomes',         true,   NULL::integer   UNION ALL
    SELECT 10000,  'Financial Incomes',            true,   NULL::integer   UNION ALL
    SELECT 11000,  'Financial Expenses',           true,   NULL::integer   UNION ALL
    SELECT 11100,  'Interest Expenses',            true,   11000           UNION ALL
    SELECT 12000,  'Profit Before Income Taxes',   false,  NULL::integer   UNION ALL
    SELECT 13000,  'Income Taxes',                 true,   NULL::integer   UNION ALL
    SELECT 13001,  'Income Tax Provison',          false,  13000            UNION ALL
    SELECT 14000,  'Net Profit',                   true,   NULL::integer;

    UPDATE pl_temp SET is_debit = true WHERE item_id IN(2001, 3000, 4000);
    UPDATE pl_temp SET is_profit = true WHERE item_id IN(6000,8000, 12000, 14000);
    
    INSERT INTO pl_temp(item_id, account_id, item, parent_item_id, is_debit)
    SELECT id, account_id, account_name, 1000 as parent_item_id, false as is_debit FROM core.get_account_view_by_account_master_id(20100, 1000) UNION ALL--Sales Accounts
    SELECT id, account_id, account_name, 2000 as parent_item_id, true as is_debit FROM core.get_account_view_by_account_master_id(20400, 2001) UNION ALL--COGS Accounts
    SELECT id, account_id, account_name, 5000 as parent_item_id, true as is_debit FROM core.get_account_view_by_account_master_id(20500, 5000) UNION ALL--Direct Cost
    SELECT id, account_id, account_name, 7000 as parent_item_id, true as is_debit FROM core.get_account_view_by_account_master_id(20600, 7000) UNION ALL--Operating Expenses
    SELECT id, account_id, account_name, 9000 as parent_item_id, false as is_debit FROM core.get_account_view_by_account_master_id(20200, 9000) UNION ALL--Nonoperating Incomes
    SELECT id, account_id, account_name, 10000 as parent_item_id, false as is_debit FROM core.get_account_view_by_account_master_id(20300, 10000) UNION ALL--Financial Incomes
    SELECT id, account_id, account_name, 11000 as parent_item_id, true as is_debit FROM core.get_account_view_by_account_master_id(20700, 11000) UNION ALL--Financial Expenses
    SELECT id, account_id, account_name, 11100 as parent_item_id, true as is_debit FROM core.get_account_view_by_account_master_id(20701, 11100) UNION ALL--Interest Expenses
    SELECT id, account_id, account_name, 13000 as parent_item_id, true as is_debit FROM core.get_account_view_by_account_master_id(20800, 13001);--Income Tax Expenses

    IF(NOT _is_periodic) THEN
        DELETE FROM pl_temp WHERE item_id IN(2001, 3000, 4000);
    END IF;
    --PL structure setup end


    FOR this IN SELECT * FROM explode_array(_periods) ORDER BY date_from ASC
    LOOP
        --Updating credit balances of individual GL accounts.
        _sql := 'UPDATE pl_temp SET "' || this.period_name || '"=tran.total_amount
        FROM
        (
            SELECT finance.verified_transaction_mat_view.account_id,
            SUM(CASE tran_type WHEN ''Cr'' THEN amount_in_local_currency ELSE 0 END) - 
            SUM(CASE tran_type WHEN ''Dr'' THEN amount_in_local_currency ELSE 0 END) AS total_amount
        FROM finance.verified_transaction_mat_view
        WHERE value_date >=''' || this.date_from::text || ''' AND value_date <=''' || this.date_to::text ||
        ''' AND office_id IN (SELECT * FROM core.get_office_ids(' || _office_id::text || '))
        GROUP BY finance.verified_transaction_mat_view.account_id
        ) AS tran
        WHERE tran.account_id = pl_temp.account_id';
        EXECUTE _sql;

        --Reversing to debit balance for expense headings.
        _sql := 'UPDATE pl_temp SET "' || this.period_name || '"="' || this.period_name || '"*-1 WHERE is_debit;';
        EXECUTE _sql;

        --Getting purchase and stock balances if this is a periodic inventory system.
        --In perpetual accounting system, one would not need to include these headings 
        --because the COGS A/C would be automatically updated on each transaction.
        IF(_is_periodic) THEN
            _sql := 'UPDATE pl_temp SET "' || this.period_name || '"=finance.get_closing_stock(''' || (this.date_from::TIMESTAMP - INTERVAL '1 day')::text ||  ''', ' || _office_id::text || ') WHERE item_id=2001;';
            EXECUTE _sql;

            _sql := 'UPDATE pl_temp SET "' || this.period_name || '"=finance.get_purchase(''' || this.date_from::text ||  ''', ''' || this.date_to::text || ''', ' || _office_id::text || ') *-1 WHERE item_id=3000;';
            EXECUTE _sql;

            _sql := 'UPDATE pl_temp SET "' || this.period_name || '"=finance.get_closing_stock(''' || this.date_from::text ||  ''', ' || _office_id::text || ') WHERE item_id=4000;';
            EXECUTE _sql;
        END IF;
    END LOOP;

    --Updating the column "amount" on each row by the sum of all periods.
    SELECT 'UPDATE pl_temp SET amount = ' || array_to_string(array_agg('COALESCE("' || period_name || '", 0)'), ' +') || ';'::text INTO _sql
    FROM explode_array(_periods);

    EXECUTE _sql;

    --Updating amount and periodic balances on parent item by the sum of their respective child balances.
    SELECT 'UPDATE pl_temp SET amount = tran.amount, ' || array_to_string(array_agg('"' || period_name || '"=tran."' || period_name || '"'), ',') || 
    ' FROM 
    (
        SELECT parent_item_id,
        SUM(amount) AS amount, '
        || array_to_string(array_agg('SUM("' || period_name || '") AS "' || period_name || '"'), ',') || '
         FROM pl_temp
        GROUP BY parent_item_id
    ) 
    AS tran
        WHERE tran.parent_item_id = pl_temp.item_id;'
    INTO _sql
    FROM explode_array(_periods);
    EXECUTE _sql;

    --Updating Gross Profit.
    --Gross Profit = Revenue - (Cost of Sales + Direct Costs)
    SELECT 'UPDATE pl_temp SET amount = tran.amount, ' || array_to_string(array_agg('"' || period_name || '"=tran."' || period_name || '"'), ',') 
    || ' FROM 
    (
        SELECT
        SUM(CASE item_id WHEN 1000 THEN amount ELSE amount * -1 END) AS amount, '
        || array_to_string(array_agg('SUM(CASE item_id WHEN 1000 THEN "' || period_name || '" ELSE "' || period_name || '" *-1 END) AS "' || period_name || '"'), ',') ||
    '
         FROM pl_temp
         WHERE item_id IN
         (
             1000,2000,5000
         )
    ) 
    AS tran
    WHERE item_id = 6000;'
    INTO _sql
    FROM explode_array(_periods);

    EXECUTE _sql;


    --Updating Operating Profit.
    --Operating Profit = Gross Profit - Operating Expenses
    SELECT 'UPDATE pl_temp SET amount = tran.amount, ' || array_to_string(array_agg('"' || period_name || '"=tran."' || period_name || '"'), ',') 
    || ' FROM 
    (
        SELECT
        SUM(CASE item_id WHEN 6000 THEN amount ELSE amount * -1 END) AS amount, '
        || array_to_string(array_agg('SUM(CASE item_id WHEN 6000 THEN "' || period_name || '" ELSE "' || period_name || '" *-1 END) AS "' || period_name || '"'), ',') ||
    '
         FROM pl_temp
         WHERE item_id IN
         (
             6000, 7000
         )
    ) 
    AS tran
    WHERE item_id = 8000;'
    INTO _sql
    FROM explode_array(_periods);

    EXECUTE _sql;

    --Updating Profit Before Income Taxes.
    --Profit Before Income Taxes = Operating Profit + Nonoperating Incomes + Financial Incomes - Financial Expenses
    SELECT 'UPDATE pl_temp SET amount = tran.amount, ' || array_to_string(array_agg('"' || period_name || '"=tran."' || period_name || '"'), ',') 
    || ' FROM 
    (
        SELECT
        SUM(CASE WHEN item_id IN(11000, 11100) THEN amount *-1 ELSE amount END) AS amount, '
        || array_to_string(array_agg('SUM(CASE WHEN item_id IN(11000, 11100) THEN "' || period_name || '"*-1  ELSE "' || period_name || '" END) AS "' || period_name || '"'), ',') ||
    '
         FROM pl_temp
         WHERE item_id IN
         (
             8000, 9000, 10000, 11000, 11100
         )
    ) 
    AS tran
    WHERE item_id = 12000;'
    INTO _sql
    FROM explode_array(_periods);

    EXECUTE _sql;

    --Updating Income Tax Provison.
    --Income Tax Provison = Profit Before Income Taxes * Income Tax Rate - Paid Income Taxes
    SELECT * INTO this FROM pl_temp WHERE item_id = 12000;
    
    _sql := 'UPDATE pl_temp SET amount = core.get_income_tax_provison_amount(' || _office_id::text || ',' || this.amount::text || ',(SELECT amount FROM pl_temp WHERE item_id = 13000)), ' 
    || array_to_string(array_agg('"' || period_name || '"=core.get_income_tax_provison_amount(' || _office_id::text || ',' || core.get_field(hstore(this.*), period_name) || ', (SELECT "' || period_name || '" FROM pl_temp WHERE item_id = 13000))'), ',')
            || ' WHERE item_id = 13001;'
    FROM explode_array(_periods);

    EXECUTE _sql;

    --Updating amount and periodic balances on parent item by the sum of their respective child balances, once again to add the Income Tax Provison to Income Tax Expenses.
    SELECT 'UPDATE pl_temp SET amount = tran.amount, ' || array_to_string(array_agg('"' || period_name || '"=tran."' || period_name || '"'), ',') 
    || ' FROM 
    (
        SELECT parent_item_id,
        SUM(amount) AS amount, '
        || array_to_string(array_agg('SUM("' || period_name || '") AS "' || period_name || '"'), ',') ||
    '
         FROM pl_temp
        GROUP BY parent_item_id
    ) 
    AS tran
        WHERE tran.parent_item_id = pl_temp.item_id;'
    INTO _sql
    FROM explode_array(_periods);
    EXECUTE _sql;


    --Updating Net Profit.
    --Net Profit = Profit Before Income Taxes - Income Tax Expenses
    SELECT 'UPDATE pl_temp SET amount = tran.amount, ' || array_to_string(array_agg('"' || period_name || '"=tran."' || period_name || '"'), ',') 
    || ' FROM 
    (
        SELECT
        SUM(CASE item_id WHEN 13000 THEN amount *-1 ELSE amount END) AS amount, '
        || array_to_string(array_agg('SUM(CASE item_id WHEN 13000 THEN "' || period_name || '"*-1  ELSE "' || period_name || '" END) AS "' || period_name || '"'), ',') ||
    '
         FROM pl_temp
         WHERE item_id IN
         (
             12000, 13000
         )
    ) 
    AS tran
    WHERE item_id = 14000;'
    INTO _sql
    FROM explode_array(_periods);

    EXECUTE _sql;

    --Removing ledgers having zero balances
    DELETE FROM pl_temp
    WHERE COALESCE(amount, 0) = 0
    AND account_id IS NOT NULL;


    --Dividing by the factor.
    SELECT 'UPDATE pl_temp SET amount = amount /' || _factor::text || ',' || array_to_string(array_agg('"' || period_name || '"="' || period_name || '"/' || _factor::text), ',') || ';'
    INTO _sql
    FROM explode_array(_periods);
    EXECUTE _sql;


    --Converting 0's to NULLS.
    SELECT 'UPDATE pl_temp SET amount = CASE WHEN amount = 0 THEN NULL ELSE amount END,' || array_to_string(array_agg('"' || period_name || '"= CASE WHEN "' || period_name || '" = 0 THEN NULL ELSE "' || period_name || '" END'), ',') || ';'
    INTO _sql
    FROM explode_array(_periods);

    EXECUTE _sql;

    IF(_compact) THEN
        SELECT array_to_json(array_agg(row_to_json(report)))
        INTO _json
        FROM
        (
            SELECT item, amount, is_profit, is_summation
            FROM pl_temp
            ORDER BY item_id
        ) AS report;
    ELSE
        SELECT 
        'SELECT array_to_json(array_agg(row_to_json(report)))
        FROM
        (
            SELECT item, amount,'
            || array_to_string(array_agg('"' || period_name || '"'), ',') ||
            ', is_profit, is_summation FROM pl_temp
            ORDER BY item_id
        ) AS report;'
        INTO _sql
        FROM explode_array(_periods);

        EXECUTE _sql INTO _json ;
    END IF;    

    RETURN _json;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/logic/finance.get_retained_earnings.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_retained_earnings
(
    _date_to                        date,
    _office_id                      integer,
    _factor                         integer
);

CREATE FUNCTION finance.get_retained_earnings
(
    _date_to                        date,
    _office_id                      integer,
    _factor                         integer
)
RETURNS decimal(24, 4)
AS
$$
    DECLARE     _date_from              date;
    DECLARE     _net_profit             decimal(24, 4);
    DECLARE     _paid_dividends         decimal(24, 4);
BEGIN
    IF(COALESCE(_factor, 0) = 0) THEN
        _factor := 1;
    END IF;
    _date_from              := finance.get_fiscal_year_start_date(_office_id);    
    _net_profit             := finance.get_net_profit(_date_from, _date_to, _office_id, _factor, true);

    SELECT 
        COALESCE(SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE amount_in_local_currency * -1 END) / _factor, 0)
    INTO 
        _paid_dividends
    FROM finance.verified_transaction_mat_view
    WHERE value_date <=_date_to
    AND account_master_id BETWEEN 15300 AND 15400
    AND office_id IN (SELECT * FROM core.get_office_ids(_office_id));
    
    RETURN _net_profit - _paid_dividends;
END
$$
LANGUAGE plpgsql;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/logic/finance.get_trial_balance.sql --<--<--
DROP FUNCTION IF EXISTS finance.get_trial_balance
(
    _date_from                      date,
    _date_to                        date,
    _user_id                        integer,
    _office_id                      integer,
    _compact                        boolean,
    _factor                         decimal(24, 4),
    _change_side_when_negative      boolean,
    _include_zero_balance_accounts  boolean
);

CREATE FUNCTION finance.get_trial_balance
(
    _date_from                      date,
    _date_to                        date,
    _user_id                        integer,
    _office_id                      integer,
    _compact                        boolean,
    _factor                         decimal(24, 4),
    _change_side_when_negative      boolean DEFAULT(true),
    _include_zero_balance_accounts  boolean DEFAULT(true)
)
RETURNS TABLE
(
    id                      integer,
    account_id              integer,
    account_number          text,
    account                 text,
    previous_debit          decimal(24, 4),
    previous_credit         decimal(24, 4),
    debit                   decimal(24, 4),
    credit                  decimal(24, 4),
    closing_debit           decimal(24, 4),
    closing_credit          decimal(24, 4)
)
AS
$$
BEGIN
    IF(_date_from = 'infinity') THEN
        RAISE EXCEPTION 'Invalid date.'
        USING ERRCODE='P3008';
    END IF;

    IF NOT EXISTS
    (
        SELECT 0 FROM core.offices
        WHERE office_id IN 
        (
            SELECT * FROM core.get_office_ids(_office_id)
        )
        HAVING count(DISTINCT currency_code) = 1
   ) THEN
        RAISE EXCEPTION 'Cannot produce trial balance of office(s) having different base currencies.'
        USING ERRCODE='P8002';
   END IF;


    DROP TABLE IF EXISTS temp_trial_balance;
    CREATE TEMPORARY TABLE temp_trial_balance
    (
        id                      integer,
        account_id              integer,
        account_number          text,
        account                 text,
        previous_debit          decimal(24, 4),
        previous_credit         decimal(24, 4),
        debit                   decimal(24, 4),
        credit                  decimal(24, 4),
        closing_debit           decimal(24, 4),
        closing_credit          decimal(24, 4),
        root_account_id         integer,
        normally_debit          boolean
    ) ON COMMIT DROP;

    INSERT INTO temp_trial_balance(account_id, previous_debit, previous_credit)    
    SELECT 
        verified_transaction_mat_view.account_id, 
        SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE 0 END),
        SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE 0 END)        
    FROM finance.verified_transaction_mat_view
    WHERE value_date < _date_from
    AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
    GROUP BY verified_transaction_mat_view.account_id;

    IF(_date_to = 'infinity') THEN
        INSERT INTO temp_trial_balance(account_id, debit, credit)    
        SELECT 
            verified_transaction_mat_view.account_id, 
            SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE 0 END),
            SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE 0 END)        
        FROM finance.verified_transaction_mat_view
        WHERE value_date > _date_from
        AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        GROUP BY verified_transaction_mat_view.account_id;
    ELSE
        INSERT INTO temp_trial_balance(account_id, debit, credit)    
        SELECT 
            verified_transaction_mat_view.account_id, 
            SUM(CASE tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE 0 END),
            SUM(CASE tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE 0 END)        
        FROM finance.verified_transaction_mat_view
        WHERE value_date >= _date_from AND value_date <= _date_to
        AND office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        GROUP BY verified_transaction_mat_view.account_id;    
    END IF;

    UPDATE temp_trial_balance SET root_account_id = finance.get_root_account_id(temp_trial_balance.account_id);


    DROP TABLE IF EXISTS temp_trial_balance2;
    
    IF(_compact) THEN
        CREATE TEMPORARY TABLE temp_trial_balance2
        ON COMMIT DROP
        AS
        SELECT
            temp_trial_balance.root_account_id AS account_id,
            ''::text as account_number,
            ''::text as account,
            SUM(temp_trial_balance.previous_debit) AS previous_debit,
            SUM(temp_trial_balance.previous_credit) AS previous_credit,
            SUM(temp_trial_balance.debit) AS debit,
            SUM(temp_trial_balance.credit) as credit,
            SUM(temp_trial_balance.closing_debit) AS closing_debit,
            SUM(temp_trial_balance.closing_credit) AS closing_credit,
            temp_trial_balance.normally_debit
        FROM temp_trial_balance
        GROUP BY 
            temp_trial_balance.root_account_id,
            temp_trial_balance.normally_debit
        ORDER BY temp_trial_balance.normally_debit;
    ELSE
        CREATE TEMPORARY TABLE temp_trial_balance2
        ON COMMIT DROP
        AS
        SELECT
            temp_trial_balance.account_id,
            ''::text as account_number,
            ''::text as account,
            SUM(temp_trial_balance.previous_debit) AS previous_debit,
            SUM(temp_trial_balance.previous_credit) AS previous_credit,
            SUM(temp_trial_balance.debit) AS debit,
            SUM(temp_trial_balance.credit) as credit,
            SUM(temp_trial_balance.closing_debit) AS closing_debit,
            SUM(temp_trial_balance.closing_credit) AS closing_credit,
            temp_trial_balance.normally_debit
        FROM temp_trial_balance
        GROUP BY 
            temp_trial_balance.account_id,
            temp_trial_balance.normally_debit
        ORDER BY temp_trial_balance.normally_debit;
    END IF;
    
    UPDATE temp_trial_balance2 SET
        account_number = finance.accounts.account_number,
        account = finance.accounts.account_name,
        normally_debit = finance.account_masters.normally_debit
    FROM finance.accounts
    INNER JOIN finance.account_masters
    ON finance.accounts.account_master_id = finance.account_masters.account_master_id
    WHERE temp_trial_balance2.account_id = finance.accounts.account_id;

    UPDATE temp_trial_balance2 SET 
        closing_debit = COALESCE(temp_trial_balance2.previous_debit, 0) + COALESCE(temp_trial_balance2.debit, 0),
        closing_credit = COALESCE(temp_trial_balance2.previous_credit, 0) + COALESCE(temp_trial_balance2.credit, 0);
        


     UPDATE temp_trial_balance2 SET previous_debit = COALESCE(temp_trial_balance2.previous_debit, 0) - COALESCE(temp_trial_balance2.previous_credit, 0), previous_credit = NULL WHERE normally_debit;
     UPDATE temp_trial_balance2 SET previous_credit = COALESCE(temp_trial_balance2.previous_credit, 0) - COALESCE(temp_trial_balance2.previous_debit, 0), previous_debit = NULL WHERE NOT normally_debit;
 
     UPDATE temp_trial_balance2 SET debit = COALESCE(temp_trial_balance2.debit, 0) - COALESCE(temp_trial_balance2.credit, 0), credit = NULL WHERE normally_debit;
     UPDATE temp_trial_balance2 SET credit = COALESCE(temp_trial_balance2.credit, 0) - COALESCE(temp_trial_balance2.debit, 0), debit = NULL WHERE NOT normally_debit;
 
     UPDATE temp_trial_balance2 SET closing_debit = COALESCE(temp_trial_balance2.closing_debit, 0) - COALESCE(temp_trial_balance2.closing_credit, 0), closing_credit = NULL WHERE normally_debit;
     UPDATE temp_trial_balance2 SET closing_credit = COALESCE(temp_trial_balance2.closing_credit, 0) - COALESCE(temp_trial_balance2.closing_debit, 0), closing_debit = NULL WHERE NOT normally_debit;


    IF(NOT _include_zero_balance_accounts) THEN
        DELETE FROM temp_trial_balance2 WHERE COALESCE(temp_trial_balance2.closing_debit) + COALESCE(temp_trial_balance2.closing_credit) = 0;
    END IF;
    
    IF(_factor > 0) THEN
        UPDATE temp_trial_balance2 SET previous_debit   = temp_trial_balance2.previous_debit/_factor;
        UPDATE temp_trial_balance2 SET previous_credit  = temp_trial_balance2.previous_credit/_factor;
        UPDATE temp_trial_balance2 SET debit            = temp_trial_balance2.debit/_factor;
        UPDATE temp_trial_balance2 SET credit           = temp_trial_balance2.credit/_factor;
        UPDATE temp_trial_balance2 SET closing_debit    = temp_trial_balance2.closing_debit/_factor;
        UPDATE temp_trial_balance2 SET closing_credit   = temp_trial_balance2.closing_credit/_factor;
    END IF;

    --Remove Zeros
    UPDATE temp_trial_balance2 SET previous_debit = NULL WHERE temp_trial_balance2.previous_debit = 0;
    UPDATE temp_trial_balance2 SET previous_credit = NULL WHERE temp_trial_balance2.previous_credit = 0;
    UPDATE temp_trial_balance2 SET debit = NULL WHERE temp_trial_balance2.debit = 0;
    UPDATE temp_trial_balance2 SET credit = NULL WHERE temp_trial_balance2.credit = 0;
    UPDATE temp_trial_balance2 SET closing_debit = NULL WHERE temp_trial_balance2.closing_debit = 0;
    UPDATE temp_trial_balance2 SET closing_debit = NULL WHERE temp_trial_balance2.closing_credit = 0;

    IF(_change_side_when_negative) THEN
        UPDATE temp_trial_balance2 SET previous_debit = temp_trial_balance2.previous_credit * -1, previous_credit = NULL WHERE temp_trial_balance2.previous_credit < 0;
        UPDATE temp_trial_balance2 SET previous_credit = temp_trial_balance2.previous_debit * -1, previous_debit = NULL WHERE temp_trial_balance2.previous_debit < 0;

        UPDATE temp_trial_balance2 SET debit = temp_trial_balance2.credit * -1, credit = NULL WHERE temp_trial_balance2.credit < 0;
        UPDATE temp_trial_balance2 SET credit = temp_trial_balance2.debit * -1, debit = NULL WHERE temp_trial_balance2.debit < 0;

        UPDATE temp_trial_balance2 SET closing_debit = temp_trial_balance2.closing_credit * -1, closing_credit = NULL WHERE temp_trial_balance2.closing_credit < 0;
        UPDATE temp_trial_balance2 SET closing_credit = temp_trial_balance2.closing_debit * -1, closing_debit = NULL WHERE temp_trial_balance2.closing_debit < 0;
    END IF;
    
    RETURN QUERY
    SELECT
        row_number() OVER(ORDER BY temp_trial_balance2.normally_debit DESC, temp_trial_balance2.account_id)::integer AS id,
        temp_trial_balance2.account_id,
        temp_trial_balance2.account_number,
        temp_trial_balance2.account,
        temp_trial_balance2.previous_debit,
        temp_trial_balance2.previous_credit,
        temp_trial_balance2.debit,
        temp_trial_balance2.credit,
        temp_trial_balance2.closing_debit,
        temp_trial_balance2.closing_credit
    FROM temp_trial_balance2;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/02.triggers/finance.update_transaction_meta.sql --<--<--
DROP FUNCTION IF EXISTS finance.update_transaction_meta() CASCADE;

CREATE FUNCTION finance.update_transaction_meta()
RETURNS TRIGGER
AS
$$
    DECLARE _transaction_master_id          bigint;
    DECLARE _current_transaction_counter    integer;
    DECLARE _current_transaction_code       national character varying(50);
    DECLARE _value_date                     date;
    DECLARE _office_id                      integer;
    DECLARE _user_id                        integer;
    DECLARE _login_id                       bigint;
BEGIN
    _transaction_master_id                  := NEW.transaction_master_id;
    _current_transaction_counter            := NEW.transaction_counter;
    _current_transaction_code               := NEW.transaction_code;
    _value_date                             := NEW.value_date;
    _office_id                              := NEW.office_id;
    _user_id                                := NEW.user_id;
    _login_id                               := NEW.login_id;

    IF(COALESCE(_current_transaction_code, '') = '') THEN
        UPDATE finance.transaction_master
        SET transaction_code = finance.get_transaction_code(_value_date, _office_id, _user_id, _login_id)
        WHERE transaction_master_id = _transaction_master_id;
    END IF;

    IF(COALESCE(_current_transaction_counter, 0) = 0) THEN
        UPDATE finance.transaction_master
        SET transaction_counter = finance.get_new_transaction_counter(_value_date)
        WHERE transaction_master_id = _transaction_master_id;
    END IF;

    RETURN NEW;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER update_transaction_meta
AFTER INSERT
ON finance.transaction_master
FOR EACH ROW EXECUTE PROCEDURE finance.update_transaction_meta();


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/03.menus/menus.sql --<--<--
DELETE FROM auth.menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'Finance'
);

DELETE FROM auth.group_menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'Finance'
);

DELETE FROM core.menus
WHERE app_name = 'Finance';


SELECT * FROM core.create_app('Finance', 'Finance', '1.0', 'MixERP Inc.', 'December 1, 2015', 'book red', '/dashboard/finance/tasks/journal/entry', NULL::text[]);

SELECT * FROM core.create_menu('Finance', 'Tasks', '', 'lightning', '');
SELECT * FROM core.create_menu('Finance', 'Journal Entry', '/dashboard/finance/tasks/journal/entry', 'user', 'Tasks');
SELECT * FROM core.create_menu('Finance', 'Exchange Rates', '/dashboard/finance/tasks/exchange-rates', 'ticket', 'Tasks');
SELECT * FROM core.create_menu('Finance', 'Journal Verification', '/dashboard/finance/tasks/journal/verification', 'food', 'Tasks');
SELECT * FROM core.create_menu('Finance', 'Verification Policy', '/dashboard/finance/tasks/verification-policy', 'keyboard', 'Tasks');
SELECT * FROM core.create_menu('Finance', 'Auto Verification Policy', '/dashboard/finance/tasks/verification-policy/auto', 'keyboard', 'Tasks');
SELECT * FROM core.create_menu('Finance', 'EOD Processing', '/dashboard/finance/tasks/eod-processing', 'keyboard', 'Tasks');

SELECT * FROM core.create_menu('Finance', 'Setup', 'square outline', 'configure', '');
SELECT * FROM core.create_menu('Finance', 'Chart of Account', '/dashboard/finance/setup/chart-of-accounts', 'users', 'Setup');
SELECT * FROM core.create_menu('Finance', 'Currencies', '/dashboard/finance/setup/currencies', 'users', 'Setup');
SELECT * FROM core.create_menu('Finance', 'Bank Accounts', '/dashboard/finance/setup/bank-accounts', 'users', 'Setup');
SELECT * FROM core.create_menu('Finance', 'Cash Flow Headings', '/dashboard/finance/setup/cash-flow/headings', 'desktop', 'Setup');
SELECT * FROM core.create_menu('Finance', 'Cash Flow Setup', '/dashboard/finance/setup/cash-flow/setup', 'film', 'Setup');
SELECT * FROM core.create_menu('Finance', 'Cost Centers', '/dashboard/finance/setup/cost-centers', 'square outline', 'Setup');
SELECT * FROM core.create_menu('Finance', 'Cash Repositories', '/dashboard/finance/setup/cash-repositories', 'money', 'Setup');

SELECT * FROM core.create_menu('Finance', 'Reports', '', 'configure', '');
SELECT * FROM core.create_menu('Finance', 'Account Statement', '/dashboard/reports/view/Areas/MixERP.Finance/Reports/AccountStatement.xml', 'money', 'Reports');
SELECT * FROM core.create_menu('Finance', 'Trial Balance', '/dashboard/reports/view/Areas/MixERP.Finance/Reports/TrialBalance.xml', 'money', 'Reports');
SELECT * FROM core.create_menu('Finance', 'Profit & Loss Account', '/dashboard/finance/reports/pl-account', 'money', 'Reports');
SELECT * FROM core.create_menu('Finance', 'Retained Earnings Statement', '/dashboard/reports/view/Areas/MixERP.Finance/Reports/RetainedEarnings.xml', 'money', 'Reports');
SELECT * FROM core.create_menu('Finance', 'Balance Sheet', '/dashboard/reports/view/Areas/MixERP.Finance/Reports/BalanceSheet.xml', 'money', 'Reports');
SELECT * FROM core.create_menu('Finance', 'Cash Flow', '/dashboard/finance/reports/cash-flow', 'money', 'Reports');
SELECT * FROM core.create_menu('Finance', 'Exchange Rate Report', '/dashboard/reports/view/Areas/MixERP.Finance/Reports/ExchangeRates.xml', 'money', 'Reports');

SELECT * FROM auth.create_app_menu_policy
(
    'Admin', 
    core.get_office_id_by_office_name('Default'), 
    'Finance',
    '{*}'::text[]
);



-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.account_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.account_scrud_view CASCADE;

CREATE VIEW finance.account_scrud_view
AS
SELECT
    finance.accounts.account_id,
    finance.account_masters.account_master_code || ' (' || finance.account_masters.account_master_name || ')' AS account_master,
    finance.accounts.account_number,
    finance.accounts.external_code,
	core.currencies.currency_code || ' ('|| core.currencies.currency_name|| ')' currency,
    finance.accounts.account_name,
    finance.accounts.description,
	finance.accounts.confidential,
	finance.accounts.is_transaction_node,
    finance.accounts.sys_type,
    finance.accounts.account_master_id,
    parent_account.account_number || ' (' || parent_account.account_name || ')' AS parent    
FROM finance.accounts
INNER JOIN finance.account_masters
ON finance.account_masters.account_master_id=finance.accounts.account_master_id
LEFT JOIN core.currencies
ON finance.accounts.currency_code = core.currencies.currency_code
LEFT JOIN finance.accounts parent_account
ON parent_account.account_id=finance.accounts.parent_account_id
WHERE NOT finance.accounts.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.auto_verification_policy_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.auto_verification_policy_scrud_view;


CREATE VIEW finance.auto_verification_policy_scrud_view
AS
SELECT
    finance.auto_verification_policy.auto_verification_policy_id,
    finance.auto_verification_policy.user_id,
    account.get_name_by_user_id(finance.auto_verification_policy.user_id),
    finance.auto_verification_policy.office_id,
    core.get_office_name_by_office_id(finance.auto_verification_policy.office_id),
    finance.auto_verification_policy.effective_from,
    finance.auto_verification_policy.ends_on,
    finance.auto_verification_policy.is_active
FROM finance.auto_verification_policy
WHERE NOT finance.auto_verification_policy.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.bank_account_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.bank_account_scrud_view;

CREATE VIEW finance.bank_account_scrud_view
AS
SELECT 
    finance.bank_accounts.bank_account_id,
    finance.bank_accounts.account_id,
    account.users.name AS maintained_by,
    core.offices.office_code || '(' || core.offices.office_name||')' AS office_name,
	finance.bank_accounts.bank_name,
	finance.bank_accounts.bank_branch,
	finance.bank_accounts.bank_contact_number,
	finance.bank_accounts.bank_account_number,
	finance.bank_accounts.bank_account_type,
	finance.bank_accounts.relationship_officer_name
FROM finance.bank_accounts
INNER JOIN account.users
ON finance.bank_accounts.maintained_by_user_id = account.users.user_id
INNER JOIN core.offices
ON finance.bank_accounts.office_id = core.offices.office_id
WHERE NOT finance.bank_accounts.deleted;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.cash_flow_heading_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.cash_flow_heading_scrud_view;

CREATE VIEW finance.cash_flow_heading_scrud_view
AS
SELECT 
  finance.cash_flow_headings.cash_flow_heading_id, 
  finance.cash_flow_headings.cash_flow_heading_code, 
  finance.cash_flow_headings.cash_flow_heading_name, 
  finance.cash_flow_headings.cash_flow_heading_type, 
  finance.cash_flow_headings.is_debit, 
  finance.cash_flow_headings.is_sales, 
  finance.cash_flow_headings.is_purchase
FROM finance.cash_flow_headings
WHERE NOT finance.cash_flow_headings.deleted;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.cash_flow_setup_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.cash_flow_setup_scrud_view;

CREATE VIEW finance.cash_flow_setup_scrud_view
AS
SELECT 
    finance.cash_flow_setup.cash_flow_setup_id, 
    finance.cash_flow_headings.cash_flow_heading_code || '('|| finance.cash_flow_headings.cash_flow_heading_name||')' AS cash_flow_heading, 
    finance.account_masters.account_master_code || '('|| finance.account_masters.account_master_name||')' AS account_master
FROM finance.cash_flow_setup
INNER JOIN finance.cash_flow_headings
ON  finance.cash_flow_setup.cash_flow_heading_id =finance.cash_flow_headings.cash_flow_heading_id
INNER JOIN finance.account_masters
ON finance.cash_flow_setup.account_master_id = finance.account_masters.account_master_id
WHERE NOT finance.cash_flow_setup.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.cash_repository_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.cash_repository_scrud_view;

CREATE VIEW finance.cash_repository_scrud_view
AS
SELECT
    finance.cash_repositories.cash_repository_id,
    core.offices.office_code || ' (' || core.offices.office_name || ') ' AS office,
    finance.cash_repositories.cash_repository_code,
    finance.cash_repositories.cash_repository_name,
    parent_cash_repository.cash_repository_code || ' (' || parent_cash_repository.cash_repository_name || ') ' AS parent_cash_repository,
    finance.cash_repositories.description
FROM finance.cash_repositories
INNER JOIN core.offices
ON finance.cash_repositories.office_id = core.offices.office_id
LEFT JOIN finance.cash_repositories AS parent_cash_repository
ON finance.cash_repositories.parent_cash_repository_id = parent_cash_repository.parent_cash_repository_id
WHERE NOT finance.cash_repositories.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.cost_center_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.cost_center_scrud_view;

CREATE VIEW finance.cost_center_scrud_view
AS
SELECT
    finance.cost_centers.cost_center_id,
    finance.cost_centers.cost_center_code,
    finance.cost_centers.cost_center_name
FROM finance.cost_centers
WHERE NOT finance.cost_centers.deleted;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.journal_verification_policy_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.journal_verification_policy_scrud_view;


CREATE VIEW finance.journal_verification_policy_scrud_view
AS
SELECT
    finance.journal_verification_policy.journal_verification_policy_id,
    finance.journal_verification_policy.user_id,
    account.get_name_by_user_id(finance.journal_verification_policy.user_id),
    finance.journal_verification_policy.office_id,
    core.get_office_name_by_office_id(finance.journal_verification_policy.office_id),
    finance.journal_verification_policy.can_verify,
    finance.journal_verification_policy.can_self_verify,
    finance.journal_verification_policy.effective_from,
    finance.journal_verification_policy.ends_on,
    finance.journal_verification_policy.is_active
FROM finance.journal_verification_policy
WHERE NOT finance.journal_verification_policy.deleted;




-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.merchant_fee_setup_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.merchant_fee_setup_scrud_view CASCADE;

CREATE VIEW finance.merchant_fee_setup_scrud_view
AS
SELECT 
    finance.merchant_fee_setup.merchant_fee_setup_id,
    finance.bank_accounts.bank_name || ' (' || finance.bank_accounts.bank_account_number || ')' AS merchant_account,
    finance.payment_cards.payment_card_code || ' ( '|| finance.payment_cards.payment_card_name || ')' AS payment_card,
    finance.merchant_fee_setup.rate,
    finance.merchant_fee_setup.customer_pays_fee,
    finance.accounts.account_number || ' (' || finance.accounts.account_name || ')' As account,
    finance.merchant_fee_setup.statement_reference
FROM finance.merchant_fee_setup
INNER JOIN finance.bank_accounts
ON finance.merchant_fee_setup.merchant_account_id = finance.bank_accounts.account_id
INNER JOIN
finance.payment_cards
ON finance.merchant_fee_setup.payment_card_id = finance.payment_cards.payment_card_id
INNER JOIN
finance.accounts
ON finance.merchant_fee_setup.account_id = finance.accounts.account_id
WHERE NOT finance.merchant_fee_setup.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.scrud-views/finance.payment_card_scrud_view.sql --<--<--
DROP VIEW IF EXISTS finance.payment_card_scrud_view;

CREATE VIEW finance.payment_card_scrud_view
AS
SELECT 
    finance.payment_cards.payment_card_id,
    finance.payment_cards.payment_card_code,
    finance.payment_cards.payment_card_name,
    finance.card_types.card_type_code || ' (' || finance.card_types.card_type_name || ')' AS card_type
FROM finance.payment_cards
INNER JOIN finance.card_types
ON finance.payment_cards.card_type_id = finance.card_types.card_type_id
WHERE NOT finance.payment_cards.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.selector-views/finance.account_selector_view.sql --<--<--
DROP VIEW IF EXISTS finance.account_selector_view;

CREATE VIEW finance.account_selector_view
AS
SELECT
    finance.accounts.account_id,
    finance.accounts.account_number AS account_code,
    finance.accounts.account_name
FROM finance.accounts
WHERE NOT finance.accounts.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.selector-views/finance.bank_account_selector_view.sql --<--<--
DROP VIEW IF EXISTS finance.bank_account_selector_view;

CREATE VIEW finance.bank_account_selector_view
AS
SELECT 
    finance.account_scrud_view.account_id AS bank_account_id,
    finance.account_scrud_view.account_name AS bank_account_name
FROM finance.account_scrud_view
WHERE account_master_id = 10102
ORDER BY account_id;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.views/0. finance.transaction_view.sql --<--<--
DROP VIEW IF EXISTS finance.transaction_view;
CREATE VIEW finance.transaction_view
AS
SELECT
    finance.transaction_master.transaction_master_id,
    finance.transaction_master.transaction_counter,
    finance.transaction_master.transaction_code,
    finance.transaction_master.book,
    finance.transaction_master.value_date,
    finance.transaction_master.transaction_ts,
    finance.transaction_master.login_id,
    finance.transaction_master.user_id,
    finance.transaction_master.office_id,
    finance.transaction_master.cost_center_id,
    finance.transaction_master.reference_number,
    finance.transaction_master.statement_reference AS master_statement_reference,
    finance.transaction_master.last_verified_on,
    finance.transaction_master.verified_by_user_id,
    finance.transaction_master.verification_status_id,
    finance.transaction_master.verification_reason,
    finance.transaction_details.transaction_detail_id,
    finance.transaction_details.tran_type,
    finance.transaction_details.account_id,
    finance.accounts.account_number,
    finance.accounts.account_name,
    finance.account_masters.normally_debit,
    finance.account_masters.account_master_code,
    finance.account_masters.account_master_name,
    finance.accounts.account_master_id,
    finance.accounts.confidential,
    finance.transaction_details.statement_reference,
    finance.transaction_details.cash_repository_id,
    finance.transaction_details.currency_code,
    finance.transaction_details.amount_in_currency,
    finance.transaction_details.local_currency_code,
    finance.transaction_details.amount_in_local_currency
FROM finance.transaction_master
INNER JOIN finance.transaction_details
ON finance.transaction_master.transaction_master_id = finance.transaction_details.transaction_master_id
INNER JOIN finance.accounts
ON finance.transaction_details.account_id = finance.accounts.account_id
INNER JOIN finance.account_masters
ON finance.accounts.account_master_id = finance.account_masters.account_master_id
WHERE NOT finance.transaction_master.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.views/1. finance.verified_transaction_view.sql --<--<--
DROP VIEW IF EXISTS finance.verified_transaction_view CASCADE;

CREATE VIEW finance.verified_transaction_view
AS
SELECT * FROM finance.transaction_view
WHERE verification_status_id > 0;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.views/2.finance.verified_transaction_mat_view.sql --<--<--
DROP MATERIALIZED VIEW IF EXISTS finance.verified_transaction_mat_view CASCADE;

CREATE MATERIALIZED VIEW finance.verified_transaction_mat_view
AS
SELECT * FROM finance.verified_transaction_view;

ALTER MATERIALIZED VIEW finance.verified_transaction_mat_view
OWNER TO frapid_db_user;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.views/3. finance.verified_cash_transaction_mat_view.sql --<--<--
DROP MATERIALIZED VIEW IF EXISTS finance.verified_cash_transaction_mat_view;

CREATE MATERIALIZED VIEW finance.verified_cash_transaction_mat_view
AS
SELECT * FROM finance.verified_transaction_mat_view
WHERE finance.verified_transaction_mat_view.transaction_master_id
IN
(
    SELECT finance.verified_transaction_mat_view.transaction_master_id 
    FROM finance.verified_transaction_mat_view
    WHERE account_master_id IN(10101, 10102) --Cash and Bank A/C
);

ALTER MATERIALIZED VIEW finance.verified_cash_transaction_mat_view
OWNER TO frapid_db_user;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.views/finance.account_view.sql --<--<--
DROP VIEW IF EXISTS finance.account_view;

CREATE VIEW finance.account_view
AS
SELECT
    finance.accounts.account_id,
    finance.accounts.account_number || ' (' || finance.accounts.account_name || ')' AS account,
    finance.accounts.account_number,
    finance.accounts.account_name,
    finance.accounts.description,
    finance.accounts.external_code,
    finance.accounts.currency_code,
    finance.accounts.confidential,
    finance.account_masters.normally_debit,
    finance.accounts.is_transaction_node,
    finance.accounts.sys_type,
    finance.accounts.parent_account_id,
    parent_accounts.account_number AS parent_account_number,
    parent_accounts.account_name AS parent_account_name,
    parent_accounts.account_number || ' (' || parent_accounts.account_name || ')' AS parent_account,
    finance.account_masters.account_master_id,
    finance.account_masters.account_master_code,
    finance.account_masters.account_master_name,
    finance.has_child_accounts(finance.accounts.account_id) AS has_child
FROM finance.account_masters
INNER JOIN finance.accounts 
ON finance.account_masters.account_master_id = finance.accounts.account_master_id
LEFT OUTER JOIN finance.accounts AS parent_accounts 
ON finance.accounts.parent_account_id = parent_accounts.account_id
WHERE NOT finance.account_masters.deleted;

-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.views/finance.frequency_dates.sql --<--<--
DROP VIEW IF EXISTS finance.frequency_date_view;

CREATE VIEW finance.frequency_date_view
AS
SELECT 
    office_id AS office_id, 
    finance.get_value_date(office_id) AS today, 
    finance.is_new_day_started(office_id) as new_day_started,
    finance.get_month_start_date(office_id) AS month_start_date,
    finance.get_month_end_date(office_id) AS month_end_date, 
    finance.get_quarter_start_date(office_id) AS quarter_start_date, 
    finance.get_quarter_end_date(office_id) AS quarter_end_date, 
    finance.get_fiscal_half_start_date(office_id) AS fiscal_half_start_date, 
    finance.get_fiscal_half_end_date(office_id) AS fiscal_half_end_date, 
    finance.get_fiscal_year_start_date(office_id) AS fiscal_year_start_date, 
    finance.get_fiscal_year_end_date(office_id) AS fiscal_year_end_date 
FROM core.offices;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/05.views/finance.trial_balance_view.sql --<--<--
DROP MATERIALIZED VIEW IF EXISTS finance.trial_balance_view;
CREATE MATERIALIZED VIEW finance.trial_balance_view
AS
SELECT finance.get_account_name_by_account_id(account_id), 
    SUM(CASE finance.verified_transaction_view.tran_type WHEN 'Dr' THEN amount_in_local_currency ELSE NULL END) AS debit,
    SUM(CASE finance.verified_transaction_view.tran_type WHEN 'Cr' THEN amount_in_local_currency ELSE NULL END) AS Credit
FROM finance.verified_transaction_view
GROUP BY account_id;

ALTER MATERIALIZED VIEW finance.trial_balance_view
OWNER TO frapid_db_user;


-->-->-- src/Frapid.Web/Areas/MixERP.Finance/db/PostgreSQL/2.x/2.0/src/99.ownership.sql --<--<--
DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_tables 
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND tableowner <> 'frapid_db_user'
    LOOP
        EXECUTE 'ALTER TABLE '|| this.schemaname || '.' || this.tablename ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT oid::regclass::text as mat_view
    FROM   pg_class
    WHERE  relkind = 'm'
    LOOP
        EXECUTE 'ALTER TABLE '|| this.mat_view ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'ALTER '
        || CASE WHEN p.proisagg THEN 'AGGREGATE ' ELSE 'FUNCTION ' END
        || quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' 
        || pg_catalog.pg_get_function_identity_arguments(p.oid) || ') OWNER TO frapid_db_user;' AS sql
    FROM   pg_catalog.pg_proc p
    JOIN   pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE  NOT n.nspname = ANY(ARRAY['pg_catalog', 'information_schema'])
    LOOP        
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_views
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND viewowner <> 'frapid_db_user'
    LOOP
        EXECUTE 'ALTER VIEW '|| this.schemaname || '.' || this.viewname ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'ALTER SCHEMA ' || nspname || ' OWNER TO frapid_db_user;' AS sql FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
    AND nspname <> 'information_schema'
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;



DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT      'ALTER TYPE ' || n.nspname || '.' || t.typname || ' OWNER TO frapid_db_user;' AS sql
    FROM        pg_type t 
    LEFT JOIN   pg_catalog.pg_namespace n ON n.oid = t.typnamespace 
    WHERE       (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) 
    AND         NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
    AND         typtype NOT IN ('b')
    AND         n.nspname NOT IN ('pg_catalog', 'information_schema')
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_tables 
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND tableowner <> 'report_user'
    LOOP
        EXECUTE 'GRANT SELECT ON TABLE '|| this.schemaname || '.' || this.tablename ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'GRANT EXECUTE ON '
        || CASE WHEN p.proisagg THEN 'AGGREGATE ' ELSE 'FUNCTION ' END
        || quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' 
        || pg_catalog.pg_get_function_identity_arguments(p.oid) || ') TO report_user;' AS sql
    FROM   pg_catalog.pg_proc p
    JOIN   pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE  NOT n.nspname = ANY(ARRAY['pg_catalog', 'information_schema'])
    LOOP        
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_views
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND viewowner <> 'report_user'
    LOOP
        EXECUTE 'GRANT SELECT ON '|| this.schemaname || '.' || this.viewname ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'GRANT USAGE ON SCHEMA ' || nspname || ' TO report_user;' AS sql FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
    AND nspname <> 'information_schema'
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


