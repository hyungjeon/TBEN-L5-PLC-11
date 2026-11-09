{attribute 'qualified_only'}
// Loại event IO-Link (= bit 5..4 của EventQualifier)
TYPE E_IolEvtType :
(
    NOTIFICATION := 1,
    WARNING      := 2,
    ERROR        := 3
) INT;
END_TYPE

