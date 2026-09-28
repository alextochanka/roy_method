object PartialSwarm: TPartialSwarm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1056#1086#1077#1074#1086#1081' '#1084#1077#1090#1086#1076' '#1075#1083#1086#1073#1072#1083#1100#1085#1086#1081' '#1086#1087#1090#1080#1084#1080#1079#1072#1094#1080#1080
  ClientHeight = 772
  ClientWidth = 1163
  Color = clLemonchiffon
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesigned
  OnCreate = FormCreate
  TextHeight = 15
  object Label1: TLabel
    Left = 17
    Top = 8
    Width = 106
    Height = 15
    Caption = #1062#1077#1083#1077#1074#1072#1103' '#1092#1091#1085#1082#1094#1080#1103
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 20
    Top = 66
    Width = 74
    Height = 15
    Caption = #1056#1072#1079#1084#1077#1088#1085#1086#1089#1090#1100
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label3: TLabel
    Left = 20
    Top = 109
    Width = 112
    Height = 15
    Caption = #1050#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1095#1072#1089#1090#1080#1094
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label4: TLabel
    Left = 20
    Top = 153
    Width = 129
    Height = 15
    Caption = #1050#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1080#1090#1077#1088#1072#1094#1080#1081
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object PaintBox: TPaintBox
    Left = 622
    Top = 8
    Width = 340
    Height = 553
    Color = clLemonchiffon
    ParentColor = False
    OnPaint = PaintBoxPaint
  end
  object lblStatus: TLabel
    Left = 20
    Top = 722
    Width = 149
    Height = 18
    Caption = #1051#1091#1095#1096#1072#1103' '#1080#1090#1077#1088#1072#1094#1080#1103
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -15
    Font.Name = 'Verdana'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label6: TLabel
    Left = 284
    Top = 66
    Width = 99
    Height = 15
    Caption = #1050#1086#1101#1092#1092#1080#1094#1080#1077#1085#1090' C1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label7: TLabel
    Left = 284
    Top = 109
    Width = 99
    Height = 15
    Caption = #1050#1086#1101#1092#1092#1080#1094#1080#1077#1085#1090' C2'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label8: TLabel
    Left = 284
    Top = 153
    Width = 88
    Height = 15
    Caption = #1052#1072#1082#1089'. '#1089#1082#1086#1088#1086#1089#1090#1100
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label9: TLabel
    Left = 283
    Top = 197
    Width = 100
    Height = 15
    Caption = #1044#1080#1072#1087#1072#1079#1086#1085' '#1087#1086#1080#1089#1082#1072
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label10: TLabel
    Left = 20
    Top = 197
    Width = 77
    Height = 15
    Caption = #1042#1077#1089' '#1080#1085#1077#1088#1094#1080#1080
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label11: TLabel
    Left = 20
    Top = 245
    Width = 48
    Height = 15
    Caption = #1053#1072#1095'.'#1074#1077#1089'.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label12: TLabel
    Left = 284
    Top = 245
    Width = 48
    Height = 15
    Caption = #1050#1086#1085'.'#1074#1077#1089'.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label13: TLabel
    Left = 20
    Top = 293
    Width = 95
    Height = 15
    Caption = #1048#1090#1077#1088'. '#1073#1077#1079' '#1091#1083#1091#1095#1096'.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label14: TLabel
    Left = 283
    Top = 293
    Width = 79
    Height = 15
    Caption = #1050#1086#1101#1092'. '#1096#1090#1088#1072#1092#1072
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label15: TLabel
    Left = 20
    Top = 341
    Width = 92
    Height = 15
    Caption = #1063#1080#1089#1083#1086' '#1079#1072#1087#1091#1089#1082#1086#1074
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object Label5: TLabel
    Left = 20
    Top = 434
    Width = 63
    Height = 15
    Caption = #1057#1090#1072#1090#1080#1089#1090#1080#1082#1072
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object cblFunction: TComboBox
    Left = 17
    Top = 29
    Width = 220
    Height = 23
    Color = clWhitesmoke
    ItemIndex = 0
    TabOrder = 0
    Text = #1060#1091#1085#1082#1094#1080#1103' '#1057#1092#1077#1088#1099
    OnChange = cblFunctionChange
    Items.Strings = (
      #1060#1091#1085#1082#1094#1080#1103' '#1057#1092#1077#1088#1099
      #1060#1091#1085#1082#1094#1080#1103' '#1056#1072#1089#1090#1088#1080#1075#1080#1085#1072
      #1060#1091#1085#1082#1094#1080#1103' '#1064#1074#1077#1092#1077#1083#1103
      #1060#1091#1085#1082#1094#1080#1103' '#1069#1082#1083#1080
      #1060#1091#1085#1082#1094#1080#1103' '#1056#1086#1079#1077#1085#1073#1088#1086#1082#1072
      #1055#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1100#1089#1082#1072#1103' '#1092#1091#1085#1082#1094#1080#1103)
  end
  object seDimension: TSpinEdit
    Left = 168
    Top = 63
    Width = 80
    Height = 24
    MaxValue = 4
    MinValue = 2
    TabOrder = 1
    Value = 2
  end
  object seSwarmSize: TSpinEdit
    Left = 168
    Top = 106
    Width = 80
    Height = 24
    Increment = 50
    MaxValue = 1000
    MinValue = 10
    TabOrder = 2
    Value = 150
  end
  object selteration: TSpinEdit
    Left = 168
    Top = 150
    Width = 80
    Height = 24
    Increment = 5
    MaxValue = 1000
    MinValue = 1
    TabOrder = 3
    Value = 10
  end
  object btnRun: TButton
    Left = 436
    Top = 335
    Width = 117
    Height = 30
    Caption = #1047#1072#1087#1091#1089#1090#1080#1090#1100
    TabOrder = 4
    OnClick = btnRunClick
  end
  object btnClear: TButton
    Left = 397
    Top = 371
    Width = 90
    Height = 36
    Caption = #1054#1095#1080#1089#1090#1080#1090#1100
    TabOrder = 5
    OnClick = btnClearClick
  end
  object btnSave: TButton
    Left = 501
    Top = 371
    Width = 92
    Height = 37
    Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 21
    OnClick = btnSaveClick
  end
  object MemoBest: TMemo
    Left = 20
    Top = 471
    Width = 573
    Height = 218
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 6
  end
  object edSelfConfidence: TEdit
    Left = 436
    Top = 61
    Width = 80
    Height = 25
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    MaxLength = 10
    ParentFont = False
    TabOrder = 7
    Text = '1,5'
  end
  object edSocialConfidence: TEdit
    Left = 436
    Top = 104
    Width = 80
    Height = 25
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    MaxLength = 10
    ParentFont = False
    TabOrder = 8
    Text = '1,5'
  end
  object edMaxVelocity: TEdit
    Left = 436
    Top = 148
    Width = 80
    Height = 25
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    MaxLength = 10
    ParentFont = False
    TabOrder = 9
    Text = '2,0'
  end
  object edSearchRange: TEdit
    Left = 436
    Top = 192
    Width = 80
    Height = 25
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    MaxLength = 10
    ParentFont = False
    TabOrder = 10
    Text = '10,0'
  end
  object edInertiaWeight: TEdit
    Left = 168
    Top = 192
    Width = 80
    Height = 25
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    MaxLength = 10
    ParentFont = False
    TabOrder = 11
    Text = '0,7'
  end
  object edInertiaStart: TEdit
    Left = 168
    Top = 240
    Width = 80
    Height = 25
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    MaxLength = 10
    ParentFont = False
    TabOrder = 12
    Text = '0,9'
    Visible = False
  end
  object edInertiaEnd: TEdit
    Left = 436
    Top = 240
    Width = 80
    Height = 25
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    MaxLength = 10
    ParentFont = False
    TabOrder = 13
    Text = '0,2'
    Visible = False
  end
  object cbAdaptiveWeight: TCheckBox
    Left = 120
    Top = 391
    Width = 128
    Height = 17
    Caption = #1040#1076#1072#1087#1090#1080#1074#1085#1099#1081' '#1074#1077#1089
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 14
    OnClick = cbAdaptiveWeightClick
  end
  object cbMutations: TCheckBox
    Left = 20
    Top = 391
    Width = 80
    Height = 17
    Caption = #1052#1091#1090#1072#1094#1080#1080
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 15
    OnClick = cbMutationsClick
  end
  object cbPenalty: TCheckBox
    Left = 264
    Top = 391
    Width = 80
    Height = 17
    Caption = #1064#1090#1088#1072#1092#1099
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 16
    OnClick = cbPenaltyClick
  end
  object seMaxIterWithoutImprovement: TSpinEdit
    Left = 168
    Top = 290
    Width = 80
    Height = 24
    Increment = 50
    MaxValue = 1000
    MinValue = 0
    TabOrder = 17
    Value = 20
    Visible = False
  end
  object edPenaltyRatio: TEdit
    Left = 436
    Top = 288
    Width = 80
    Height = 25
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    MaxLength = 10
    ParentFont = False
    TabOrder = 18
    Text = '1000'
    Visible = False
  end
  object seRuns: TSpinEdit
    Left = 168
    Top = 338
    Width = 80
    Height = 24
    Increment = 50
    MaxValue = 1000
    MinValue = 1
    TabOrder = 19
    Value = 10
  end
  object StringGrid1: TStringGrid
    Left = 960
    Top = 8
    Width = 137
    Height = 553
    ColCount = 2
    DefaultColWidth = 80
    DefaultRowHeight = 18
    FixedCols = 0
    RowCount = 1
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect]
    TabOrder = 20
    ColWidths = (
      80
      80)
    RowHeights = (
      18)
  end
end
