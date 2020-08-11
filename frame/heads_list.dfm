object Frame2: TFrame2
  Left = 0
  Top = 0
  Width = 91
  Height = 89
  DoubleBuffered = True
  Ctl3D = False
  ParentCtl3D = False
  ParentDoubleBuffered = False
  TabOrder = 0
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 91
    Height = 76
    Align = alClient
    ExplicitLeft = 16
    ExplicitTop = 16
    ExplicitWidth = 65
    ExplicitHeight = 65
  end
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 91
    Height = 76
    Align = alClient
    Stretch = True
    OnClick = Image1Click
    OnMouseEnter = Image1MouseEnter
    OnMouseLeave = Image1MouseLeave
    ExplicitLeft = 2
    ExplicitWidth = 48
    ExplicitHeight = 48
  end
  object nickname: TLabel
    Left = 0
    Top = 76
    Width = 91
    Height = 13
    Align = alBottom
    Alignment = taCenter
    ExplicitTop = 49
    ExplicitWidth = 3
  end
end
