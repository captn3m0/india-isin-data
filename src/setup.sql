CREATE TABLE IF NOT EXISTS "ISIN"("ISIN" TEXT, "Description" TEXT, "Issuer" TEXT, "Type" TEXT COLLATE NOCASE, "Status" TEXT COLLATE NOCASE);
CREATE UNIQUE INDEX isinidx on ISIN (ISIN);
CREATE INDEX statusidx on ISIN (Status);
CREATE INDEX typeidx on ISIN (Type);
.import /tmp/ISIN-no-headers.csv ISIN --csv