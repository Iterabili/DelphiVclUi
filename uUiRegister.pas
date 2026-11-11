unit uUiRegister;

interface

procedure Register;

implementation

uses
  Classes, DesignIntf, DesignEditors, uUiCard, uUiButton, uUiCheck, uUiEdit, uUiTimeEdit, uUiMemo, uUiSelect,
  uUiDatePicker, uUiTable, uUiForm;

procedure Register;
begin
  RegisterCustomModule(TUiForm, TCustomModule);
  RegisterComponents('Vcl Ui', [TUiCard, TUiButton, TUiCheck, TUiEdit, TUiTimeEdit, TUiMemo, TUiSelect,
    TUiDatePicker, TUiTable]);
end;

end.
