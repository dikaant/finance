﻿DROP FUNCTION IF EXISTS finance.get_account_statement
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
