unit uUiRegister;

interface

procedure Register;

implementation

uses
  Classes, Controls, DesignIntf, DesignEditors, uUiCard, uUiButton, uUiCheck, uUiEdit, uUiTimeEdit, uUiMemo,
  uUiSelect, uUiDatePicker, uUiColorPicker, uUiTable, uUiTabs, uUiListBox, uUiForm, uUiBarChart;

type
  TUiTabsEditor = class(TComponentEditor)
  private
    function Tabs: TUiTabs;
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

function TUiTabsEditor.Tabs: TUiTabs;
begin
  if Component is TUiTabSheet then
    Result := TUiTabSheet(Component).Tabs
  else
    Result := Component as TUiTabs;
end;

function TUiTabsEditor.GetVerbCount: Integer;
begin
  Result := 3;
end;

function TUiTabsEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0:
      Result := 'New Page';
    1:
      Result := 'Next Page';
  else
    Result := 'Previous Page';
  end;
end;

procedure TUiTabsEditor.ExecuteVerb(Index: Integer);
var
  vTabs: TUiTabs;
  vSheet: TUiTabSheet;
begin
  vTabs := Tabs;
  if not Assigned(vTabs) then
    Exit;
  case Index of
    0:
      begin
        vSheet := TUiTabSheet.Create(Designer.Root);
        vSheet.Name := Designer.UniqueName('UiTabSheet');
        vSheet.Caption := vSheet.Name;
        vSheet.Parent := vTabs;
        vTabs.ActivePage := vSheet;
        Designer.SelectComponent(vSheet);
      end;
    1:
      vTabs.SelectNextPage(True);
  else
    vTabs.SelectNextPage(False);
  end;
  Designer.Modified;
end;

procedure Register;
begin
  RegisterCustomModule(TUiForm, TCustomModule);
  RegisterComponents('Vcl Ui', [TUiCard, TUiButton, TUiCheck, TUiEdit, TUiTimeEdit, TUiMemo, TUiSelect,
    TUiDatePicker, TUiColorPicker, TUiTable, TUiTabs, TUiListBox, TUiCheckList, TUiBarChart]);
  RegisterNoIcon([TUiTabSheet]);
  RegisterComponentEditor(TUiTabs, TUiTabsEditor);
  RegisterComponentEditor(TUiTabSheet, TUiTabsEditor);
end;

end.
