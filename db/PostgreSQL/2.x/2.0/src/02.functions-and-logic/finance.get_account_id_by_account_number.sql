﻿DROP FUNCTION IF EXISTS finance.get_account_id_by_account_number(text);

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
