object set_frm: Tset_frm
  Left = 0
  Top = 0
  Caption = #35760#24405
  ClientHeight = 548
  ClientWidth = 771
  Color = 4539717
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poMainFormCenter
  OnMouseDown = FormMouseDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object Memo1: TMemo
    Left = 0
    Top = 31
    Width = 771
    Height = 457
    Align = alClient
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Color = 13760511
    Ctl3D = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentCtl3D = False
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
    ExplicitTop = 99
    ExplicitWidth = 352
    ExplicitHeight = 436
  end
  object ImgPanel1: TImgPanel
    Left = 0
    Top = 488
    Width = 771
    Height = 41
    Cursor = crHandPoint
    BevelOuter = bvNone
    AutoSize = False
    Stretch = False
    Parentfont = False
    Align = alBottom
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Tahoma'
    Font.Style = []
    TabOrder = 3
    Caption = #30830#23450
    OnClick = ImgPanel1Click
    TitleBar = False
    ExplicitLeft = 19
    ExplicitTop = 416
    ExplicitWidth = 322
    DesignSize = (
      771
      41)
    object Image2: TImage
      Left = 757
      Top = 28
      Width = 14
      Height = 13
      Cursor = crSizeNWSE
      Anchors = [akRight, akBottom]
      AutoSize = True
      Picture.Data = {
        0954506E67496D61676589504E470D0A1A0A0000000D494844520000000E0000
        000D080600000099DC5F7F000001394944415478DA63FCFFFF3F032960D9B265
        FF8F1F3FCEC0488AC6E52B57FF3F77E63483858505F11A419A0E1E38C0E0E1E9
        C110E0E7CB4894C659B366FD3F06749EB9B11E43664E2123488CA046909F0E1D
        3ECAA0AA24CD505C5A05D6B461D3E6FF78352E5AB8F0FF3EA0F38CF4B519F20A
        4A18614E3E76E4106E1B41366DDFBE83C1CADC10EEBCB56BD7FD3F71E20483AE
        8E36768D204DBB76EF46F1132C70EC6CAD19A2A2A23003071410E7CE5F64D052
        57843B0FECCF4387185495E5E0FE44D108B349574B15AE006CD3FEBD0C72B212
        0C55D50D60B1BD7BF72202079622B4D495509C070A086545398682A25278881E
        3D7C186223CCD3A014111C1C841210868606603F81C4B66EDBF6FFE489E30C2A
        CA2A0C8C4B972E05DBE4E0E008D7043275EFEE430CA6263A0C71F1F170E76DD8
        B001286602160300FA16C9E9B10252C70000000049454E44AE426082}
      Visible = False
      OnMouseDown = Image2MouseDown
      ExplicitLeft = 324
    end
  end
  object ImgPanel2: TImgPanel
    Left = 0
    Top = 0
    Width = 771
    Height = 1
    Cursor = crHandPoint
    BevelOuter = bvNone
    Transparent = True
    AutoSize = True
    Stretch = False
    Parentfont = False
    Align = alTop
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Tahoma'
    Font.Style = []
    TabOrder = 0
    OnMouseDown = ImgPanel2MouseDown
    TitleBar = False
    ExplicitWidth = 322
    object RadioGroup1: TRadioGroup
      Left = 384
      Top = 46
      Width = 29
      Height = 49
      Ctl3D = False
      DoubleBuffered = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentCtl3D = False
      ParentDoubleBuffered = False
      ParentFont = False
      TabOrder = 4
      Visible = False
    end
    object RadioButton1: TRadioButton
      Left = 12
      Top = 6
      Width = 69
      Height = 33
      Caption = #27599#26376
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = RadioButton1Click
    end
    object RadioButton2: TRadioButton
      Left = 110
      Top = 6
      Width = 79
      Height = 33
      Caption = #27599#22825
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = RadioButton2Click
    end
    object RadioButton3: TRadioButton
      Left = 217
      Top = 6
      Width = 65
      Height = 32
      Caption = #20415#31614
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = RadioButton3Click
    end
    object DatePicker1: TDatePicker
      Left = 19
      Top = 34
      Width = 50
      Height = 26
      BorderStyle = bsNone
      Color = 4539717
      Date = 44013.000000000000000000
      DateFormat = 'dd'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Segoe UI'
      Font.Style = []
      TabOrder = 3
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 529
    Width = 771
    Height = 19
    Panels = <>
    ExplicitLeft = -8
    ExplicitTop = 510
    ExplicitWidth = 322
  end
  object Edit1: TEdit
    Left = 0
    Top = 1
    Width = 771
    Height = 30
    Align = alTop
    Alignment = taCenter
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Color = 15790320
    Ctl3D = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentCtl3D = False
    ParentFont = False
    TabOrder = 1
    ExplicitLeft = 61
    ExplicitTop = 44
    ExplicitWidth = 195
  end
end
