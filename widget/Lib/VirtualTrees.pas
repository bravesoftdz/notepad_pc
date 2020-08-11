unit VirtualTrees;

interface

{$booleval off} 

{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_CODE OFF}

{$IF CompilerVersion >= 24}
  {$LEGACYIFEND ON}
{$IFEND}

{$if CompilerVersion >= 20}
  {$WARN IMPLICIT_STRING_CAST       OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS  OFF}
{$ifend}

{$HPPEMIT '#include <objidl.h>'}
{$HPPEMIT '#include <oleidl.h>'}
{$HPPEMIT '#include <oleacc.h>'}
{$HPPEMIT '#include <ShlObj.hpp>'}

uses
  Windows,  System.Generics.Collections,
  {$if CompilerVersion >= 18}
    oleacc,   
  {$ifend}
  Messages, SysUtils, Graphics, Controls, Forms, ImgList, ActiveX, StdCtrls, Classes, Menus, Printers, Types,
  CommCtrl, 
  Themes, UxTheme, ShlObj
  {$ifdef TntSupport}
    , TntStdCtrls       
  {$endif TntSupport}
  {$IF CompilerVersion >= 24}
  ,UITypes
  {$IFEND}
  ;

const
  VTVersion = '5.3.0';

{$if CompilerVersion < 20}
type
  UnicodeString = WideString;
  RawByteString = AnsiString;
  PByte = PAnsiChar;
{$ifend}

{$if CompilerVersion < 18}
  
  {$WARN BOUNDS_ERROR OFF}
  IAccessible = interface(IDispatch)
    ['{618736E0-3C3D-11CF-810C-00AA00389B71}']
    function Get_accParent(out ppdispParent: IDispatch): HResult; stdcall;
    function Get_accChildCount(out pcountChildren: Integer): HResult; stdcall;
    function Get_accChild(varChild: OleVariant; out ppdispChild: IDispatch): HResult; stdcall;
    function Get_accName(varChild: OleVariant; out pszName: WideString): HResult; stdcall;
    function Get_accValue(varChild: OleVariant; out pszValue: WideString): HResult; stdcall;
    function Get_accDescription(varChild: OleVariant; out pszDescription: WideString): HResult; stdcall;
    function Get_accRole(varChild: OleVariant; out pvarRole: OleVariant): HResult; stdcall;
    function Get_accState(varChild: OleVariant; out pvarState: OleVariant): HResult; stdcall;
    function Get_accHelp(varChild: OleVariant; out pszHelp: WideString): HResult; stdcall;
    function Get_accHelpTopic(out pszHelpFile: WideString; varChild: OleVariant;
                              out pidTopic: Integer): HResult; stdcall;
    function Get_accKeyboardShortcut(varChild: OleVariant; out pszKeyboardShortcut: WideString): HResult; stdcall;
    function Get_accFocus(out pvarChild: OleVariant): HResult; stdcall;
    function Get_accSelection(out pvarChildren: OleVariant): HResult; stdcall;
    function Get_accDefaultAction(varChild: OleVariant; out pszDefaultAction: WideString): HResult; stdcall;
    function accSelect(flagsSelect: Integer; varChild: OleVariant): HResult; stdcall;
    function accLocation(out pxLeft: Integer; out pyTop: Integer; out pcxWidth: Integer;
                         out pcyHeight: Integer; varChild: OleVariant): HResult; stdcall;
    function accNavigate(navDir: Integer; varStart: OleVariant; out pvarEndUpAt: OleVariant): HResult; stdcall;
    function accHitTest(xLeft: Integer; yTop: Integer; out pvarChild: OleVariant): HResult; stdcall;
    function accDoDefaultAction(varChild: OleVariant): HResult; stdcall;
    function Set_accName(varChild: OleVariant; const pszName: WideString): HResult; stdcall;
    function Set_accValue(varChild: OleVariant; const pszValue: WideString): HResult; stdcall;
  end;
{$ifend}

const
  VTTreeStreamVersion = 2;
  VTHeaderStreamVersion = 6;    

  CacheThreshold = 2000;        
                                
  FadeAnimationStepCount = 255; 
  ShadowSize = 5;               
  
  NoColumn = -1;
  InvalidColumn = -2;
  
  ckEmpty                  =  0;  
  
  ckRadioUncheckedNormal   =  1;
  ckRadioUncheckedHot      =  2;
  ckRadioUncheckedPressed  =  3;
  ckRadioUncheckedDisabled =  4;
  ckRadioCheckedNormal     =  5;
  ckRadioCheckedHot        =  6;
  ckRadioCheckedPressed    =  7;
  ckRadioCheckedDisabled   =  8;
  
  ckCheckUncheckedNormal   =  9;
  ckCheckUncheckedHot      = 10;
  ckCheckUncheckedPressed  = 11;
  ckCheckUncheckedDisabled = 12;
  ckCheckCheckedNormal     = 13;
  ckCheckCheckedHot        = 14;
  ckCheckCheckedPressed    = 15;
  ckCheckCheckedDisabled   = 16;
  ckCheckMixedNormal       = 17;
  ckCheckMixedHot          = 18;
  ckCheckMixedPressed      = 19;
  ckCheckMixedDisabled     = 20;
  
  ckButtonNormal           = 21;
  ckButtonHot              = 22;
  ckButtonPressed          = 23;
  ckButtonDisabled         = 24;
  
  ExpandTimer = 1;
  EditTimer = 2;
  HeaderTimer = 3;
  ScrollTimer = 4;
  ChangeTimer = 5;
  StructureChangeTimer = 6;
  SearchTimer = 7;
  ThemeChangedTimer = 8;

  ThemeChangedTimerDelay = 500;
  
  WM_CHANGESTATE = WM_APP + 32;
  
  CM_DENYSUBCLASSING = CM_BASE + 2000;
  
  CM_AUTOADJUST = CM_BASE + 2005;
  
  CFSTR_VIRTUALTREE = 'Virtual Tree Data';
  CFSTR_VTREFERENCE = 'Virtual Tree Reference';
  CFSTR_HTML = 'HTML Format';
  CFSTR_RTF = 'Rich Text Format';
  CFSTR_RTFNOOBJS = 'Rich Text Format Without Objects';
  CFSTR_CSV = 'CSV';
  
  IID_IDropTargetHelper: TGUID = (D1: $4657278B; D2: $411B; D3: $11D2; D4: ($83, $9A, $00, $C0, $4F, $D9, $18, $D0));
  IID_IDragSourceHelper: TGUID = (D1: $DE5BF786; D2: $477A; D3: $11D2; D4: ($83, $9D, $00, $C0, $4F, $D9, $18, $D0));
  IID_IDropTarget: TGUID = (D1: $00000122; D2: $0000; D3: $0000; D4: ($C0, $00, $00, $00, $00, $00, $00, $46));

{$if CompilerVersion<21}
  CLSID_DragDropHelper: TGUID = (D1: $4657278A; D2: $411B; D3: $11D2; D4: ($83, $9A, $00, $C0, $4F, $D9, $18, $D0));
  DSH_ALLOWDROPDESCRIPTIONTEXT = $1;

  SID_IDropTargetHelper = '{4657278B-411B-11D2-839A-00C04FD918D0}';
  SID_IDragSourceHelper = '{DE5BF786-477A-11D2-839D-00C04FD918D0}';
  SID_IDragSourceHelper2 = '{83E07D0D-0C5F-4163-BF1A-60B274051E40}';
  SID_IDropTarget = '{00000122-0000-0000-C000-000000000046}';
{$ifend}
  
  hcTFEditLinkIsNil      = 2000;
  hcTFWrongMoveError     = 2001;
  hcTFWrongStreamFormat  = 2002;
  hcTFWrongStreamVersion = 2003;
  hcTFStreamTooSmall     = 2004;
  hcTFCorruptStream1     = 2005;
  hcTFCorruptStream2     = 2006;
  hcTFClipboardFailed    = 2007;
  hcTFCannotSetUserData  = 2008;
  
  crHeaderSplit = TCursor(63);
  
  crVertSplit = TCursor(62);

  UtilityImageSize = 16; 

var 
  CF_VIRTUALTREE,
  CF_VTREFERENCE,
  CF_VRTF,
  CF_VRTFNOOBJS,   
                   
  CF_HTML,
  CF_CSV: Word;

  MMXAvailable: Boolean; 
  IsWinVistaOrAbove: Boolean;

  {$MinEnumSize 1, make enumerations as small as possible}

type
  
  EVirtualTreeError = class(Exception);

  PCardinal = ^Cardinal;
  
  TAutoScrollInterval = 1..1000;
  
  {$if CompilerVersion >= 23}
  TRealWMNCPaint = TWMNCPaint;
  {$else}
  TRealWMNCPaint = packed record
    Msg: UINT;
    Rgn: HRGN;
    lParam: LPARAM;
    Result: LRESULT;
  end;
  
  TWMPrint = packed record
    Msg: UINT;
    DC: HDC;
    Flags: LPARAM;
    Result: LRESULT;
  end;

  TWMPrintClient = TWMPrint;
  {$ifend}
  
  TVirtualNodeState = (
    vsInitialized,       
    vsChecking,          
    vsCutOrCopy,         
    vsDisabled,          
    vsDeleting,          
    vsExpanded,          
    vsHasChildren,       
    vsVisible,           
    vsSelected,          
    vsOnFreeNodeCallRequired,   
    vsAllChildrenHidden, 
    vsClearing,          
    vsMultiline,         
    vsHeightMeasured,    
    vsToggling,          
    vsFiltered           
  );
  TVirtualNodeStates = set of TVirtualNodeState;
  
  TVirtualNodeInitState = (
    ivsDisabled,
    ivsExpanded,
    ivsHasChildren,
    ivsMultiline,
    ivsSelected,
    ivsFiltered,
    ivsReInit
  );
  TVirtualNodeInitStates = set of TVirtualNodeInitState;

  TScrollBarStyle = (
    sbmRegular,
    sbm3D
  );
  
  TVTColumnOption = (
    coAllowClick,            
    coDraggable,             
    coEnabled,               
    coParentBidiMode,        
    coParentColor,           
    coResizable,             
    coShowDropMark,          
    coVisible,               
    coAutoSpring,            
    coFixed,                 
    coSmartResize,           
                             
    coAllowFocus,            
    coDisableAnimatedResize, 
    coWrapCaption,           
    coUseCaptionAlignment    
  );
  TVTColumnOptions = set of TVTColumnOption;
  
  TVTHeaderHitPosition = (
    hhiNoWhere,         
    hhiOnColumn,        
    hhiOnIcon,          
    hhiOnCheckbox       
  );
  TVTHeaderHitPositions = set of TVTHeaderHitPosition;
  
  THitPosition = (
    hiAbove,             
    hiBelow,             
    hiNowhere,           
    hiOnItem,            
    hiOnItemButton,      
    hiOnItemButtonExact, 
    hiOnItemCheckbox,    
    hiOnItemIndent,      
    hiOnItemLabel,       
    hiOnItemLeft,        
    hiOnItemRight,       
    hiOnNormalIcon,      
    hiOnStateIcon,       
    hiToLeft,            
    hiToRight,           
    hiUpperSplitter,     
    hiLowerSplitter      
  );
  THitPositions = set of THitPosition;

  TCheckType = (
    ctNone,
    ctTriStateCheckBox,
    ctCheckBox,
    ctRadioButton,
    ctButton
  );
  
  TCheckState = (
    csUncheckedNormal,  
    csUncheckedPressed, 
    csCheckedNormal,    
    csCheckedPressed,   
    csMixedNormal,      
    csMixedPressed      
  );

  TCheckImageKind = (
    ckLightCheck,     
    ckDarkCheck,      
    ckLightTick,      
    ckDarkTick,       
    ckFlat,           
    ckXP,             
    ckCustom,         
    ckSystemFlat,     
    ckSystemDefault   
  );
  
  TVTNodeAttachMode = (
    amNoWhere,        
    amInsertBefore,   
    amInsertAfter,    
    amAddChildFirst,  
    amAddChildLast    
  );
  
  TDropMode = (
    dmNowhere,
    dmAbove,
    dmOnNode,
    dmBelow
  );
  
  TDragOperation = (
    doCopy,
    doMove,
    doLink
  );
  TDragOperations = set of TDragOperation;

  TVTImageKind = (
    ikNormal,
    ikSelected,
    ikState,
    ikOverlay
  );

  TVTHintMode = (
    hmDefault,            
    hmHint,               
    hmHintAndDefault,     
    hmTooltip             
  );
  
  TVTTooltipLineBreakStyle = (
    hlbDefault,           
    hlbForceSingleLine,   
    hlbForceMultiLine     
  );

  TMouseButtons = set of TMouseButton;
  
  TItemEraseAction = (
    eaColor,   
    eaDefault, 
    eaNone     
  );
  
  TVTPaintOption = (
    toHideFocusRect,           
    toHideSelection,           
    toHotTrack,                
    toPopupMode,               
    toShowBackground,          
    toShowButtons,             
    toShowDropmark,            
    toShowHorzGridLines,       
    toShowRoot,                
    toShowTreeLines,           
    toShowVertGridLines,       
    toThemeAware,              
                               
    toUseBlendedImages,        
    toGhostedIfUnfocused,      
                               
    toFullVertGridLines,       
                               
    toAlwaysHideSelection,     
    toUseBlendedSelection,     
    toStaticBackground,        
    toChildrenAbove,           
    toFixedIndent,             
    toUseExplorerTheme,        
    toHideTreeLinesIfThemed,   
    toShowFilteredNodes        
  );
  TVTPaintOptions = set of TVTPaintOption;
  
  TVTAnimationOption = (
    toAnimatedToggle,          
    toAdvancedAnimatedToggle   
  );
  TVTAnimationOptions = set of TVTAnimationOption;
  
  TVTAutoOption = (
    toAutoDropExpand,           
    toAutoExpand,               
    toAutoScroll,               
    toAutoScrollOnExpand,       
    toAutoSort,                 
                                
    toAutoSpanColumns,          
    toAutoTristateTracking,     
    toAutoHideButtons,          
    toAutoDeleteMovedNodes,     
    toDisableAutoscrollOnFocus, 
    toAutoChangeScale,          
    toAutoFreeOnCollapse,       
    toDisableAutoscrollOnEdit,  
    toAutoBidiColumnOrdering    
                                
  );
  TVTAutoOptions = set of TVTAutoOption;
  
  TVTSelectionOption = (
    toDisableDrawSelection,    
    toExtendedFocus,           
    toFullRowSelect,           
    toLevelSelectConstraint,   
    toMiddleClickSelect,       
                               
    toMultiSelect,             
    toRightClickSelect,        
    toSiblingSelectConstraint, 
    toCenterScrollIntoView,    
    toSimpleDrawSelection      
                               
  );
  TVTSelectionOptions = set of TVTSelectionOption;
  
  TVTMiscOption = (
    toAcceptOLEDrop,            
    toCheckSupport,             
    toEditable,                 
    toFullRepaintOnResize,      
    toGridExtensions,           
    toInitOnSave,               
    toReportMode,               
    toToggleOnDblClick,         
    toWheelPanning,             
                                
    toReadOnly,                 
                                
    toVariableNodeHeight,       
    toFullRowDrag,              
                                
    toNodeHeightResize,         
    toNodeHeightDblClickResize, 
    toEditOnClick,              
    toEditOnDblClick,           
    toReverseFullExpandHotKey   
  );
  TVTMiscOptions = set of TVTMiscOption;
  
  TVTExportMode = (
    emAll,        
    emChecked,    
    emUnchecked   
  );
  
  TVTOperationKind = (
    okAutoFitColumns,
    okGetMaxColumnWidth,
    okSortNode,
    okSortTree
  );
  TVTOperationKinds = set of TVTOperationKind;

const
  DefaultPaintOptions = [toShowButtons, toShowDropmark, toShowTreeLines, toShowRoot, toThemeAware, toUseBlendedImages];
  DefaultAnimationOptions = [];
  DefaultAutoOptions = [toAutoDropExpand, toAutoTristateTracking, toAutoScrollOnExpand, toAutoDeleteMovedNodes, toAutoChangeScale, toAutoSort];
  DefaultSelectionOptions = [];
  DefaultMiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning,
    toEditOnClick];
  DefaultColumnOptions = [coAllowClick, coDraggable, coEnabled, coParentColor, coParentBidiMode, coResizable,
    coShowDropmark, coVisible, coAllowFocus];

type
  TBaseVirtualTree = class;
  TVirtualTreeClass = class of TBaseVirtualTree;

  PVirtualNode = ^TVirtualNode;

  TColumnIndex = type Integer;
  TColumnPosition = type Cardinal;
  
  TCacheEntry = record
    Node: PVirtualNode;
    AbsoluteTop: Cardinal;
  end;

  TCache = array of TCacheEntry;
  TNodeArray = array of PVirtualNode;

  TCustomVirtualTreeOptions = class(TPersistent)
  private
    FOwner: TBaseVirtualTree;
    FPaintOptions: TVTPaintOptions;
    FAnimationOptions: TVTAnimationOptions;
    FAutoOptions: TVTAutoOptions;
    FSelectionOptions: TVTSelectionOptions;
    FMiscOptions: TVTMiscOptions;
    FExportMode: TVTExportMode;
    procedure SetAnimationOptions(const Value: TVTAnimationOptions);
    procedure SetAutoOptions(const Value: TVTAutoOptions);
    procedure SetMiscOptions(const Value: TVTMiscOptions);
    procedure SetPaintOptions(const Value: TVTPaintOptions);
    procedure SetSelectionOptions(const Value: TVTSelectionOptions);
  protected
    property AnimationOptions: TVTAnimationOptions read FAnimationOptions write SetAnimationOptions
      default DefaultAnimationOptions;
    property AutoOptions: TVTAutoOptions read FAutoOptions write SetAutoOptions default DefaultAutoOptions;
    property ExportMode: TVTExportMode read FExportMode write FExportMode default emAll;
    property MiscOptions: TVTMiscOptions read FMiscOptions write SetMiscOptions default DefaultMiscOptions;
    property PaintOptions: TVTPaintOptions read FPaintOptions write SetPaintOptions default DefaultPaintOptions;
    property SelectionOptions: TVTSelectionOptions read FSelectionOptions write SetSelectionOptions
      default DefaultSelectionOptions;
  public
    constructor Create(AOwner: TBaseVirtualTree); virtual;

    procedure AssignTo(Dest: TPersistent); override;

    property Owner: TBaseVirtualTree read FOwner;
  end;

  TTreeOptionsClass = class of TCustomVirtualTreeOptions;

  TVirtualTreeOptions = class(TCustomVirtualTreeOptions)
  published
    property AnimationOptions;
    property AutoOptions;
    property ExportMode;
    property MiscOptions;
    property PaintOptions;
    property SelectionOptions;
  end;
  
  PVTReference = ^TVTReference;
  TVTReference = record
    Process: Cardinal;
    Tree: TBaseVirtualTree;
  end;

  TVirtualNode = packed record
    Index,                   
    ChildCount: Cardinal;    
    NodeHeight: Word;        
    States: TVirtualNodeStates; 
    Align: Byte;             
    CheckState: TCheckState; 
    CheckType: TCheckType;   
    Dummy: Byte;             
    TotalCount,              
    TotalHeight: Cardinal;   
    
    Parent,                  
    PrevSibling,             
    NextSibling,             
    FirstChild,              
    LastChild: PVirtualNode; 
    Data: record end;        
  end;
  
  TVTHeaderHitInfo = record
    X,
    Y: Integer;
    Button: TMouseButton;
    Shift: TShiftState;
    Column: TColumnIndex;
    HitPosition: TVTHeaderHitPositions;
  end;
  
  THitInfo = record
    HitNode: PVirtualNode;
    HitPositions: THitPositions;
    HitColumn: TColumnIndex;
  end;
  
  TScrollDirections = set of (
    sdLeft,
    sdUp,
    sdRight,
    sdDown
  );
  
  TFormatEtcArray = array of TFormatEtc;
  TFormatArray = array of Word;
  
  TInternalStgMedium = packed record
    Format: TClipFormat;
    Medium: TStgMedium;
  end;
  TInternalStgMediumArray = array of TInternalStgMedium;

  TEnumFormatEtc = class(TInterfacedObject, IEnumFormatEtc)
  private
    FTree: TBaseVirtualTree;
    FFormatEtcArray: TFormatEtcArray;
    FCurrentIndex: Integer;
  public
    constructor Create(Tree: TBaseVirtualTree; AFormatEtcArray: TFormatEtcArray);

    function Clone(out Enum: IEnumFormatEtc): HResult; stdcall;
    function Next(celt: Integer; out elt; pceltFetched: PLongint): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Skip(celt: Integer): HResult; stdcall;
  end;

{$if CompilerVersion<21}
  {$EXTERNALSYM IDropTargetHelper}

  IDropTargetHelper = interface(IUnknown)
    [SID_IDropTargetHelper]
    function DragEnter(hwndTarget: HWND; pDataObject: IDataObject; var ppt: TPoint; dwEffect: Integer): HRESULT; stdcall;
    function DragLeave: HRESULT; stdcall;
    function DragOver(var ppt: TPoint; dwEffect: Integer): HRESULT; stdcall;
    function Drop(pDataObject: IDataObject; var ppt: TPoint; dwEffect: Integer): HRESULT; stdcall;
    function Show(fShow: Boolean): HRESULT; stdcall;
  end;

  PSHDragImage = ^TSHDragImage;
  TSHDragImage = packed record
    sizeDragImage: TSize;
    ptOffset: TPoint;
    hbmpDragImage: HBITMAP;
    crColorKey: TColorRef;
  end;

  IDragSourceHelper = interface(IUnknown)
    [SID_IDragSourceHelper]
    function InitializeFromBitmap(SHDragImage: PSHDragImage; pDataObject: IDataObject): HRESULT; stdcall;
    function InitializeFromWindow(Window: HWND; var ppt: TPoint; pDataObject: IDataObject): HRESULT; stdcall;
  end;
  {$EXTERNALSYM IDragSourceHelper}

    IDragSourceHelper2 = interface(IDragSourceHelper)
  [SID_IDragSourceHelper2]
    function SetFlags(dwFlags: DWORD): HRESULT; stdcall;
  end;
  {$EXTERNALSYM IDragSourceHelper2}
{$ifend}

  IVTDragManager = interface(IUnknown)
    ['{C4B25559-14DA-446B-8901-0C879000EB16}']
    procedure ForceDragLeave; stdcall;
    function GetDataObject: IDataObject; stdcall;
    function GetDragSource: TBaseVirtualTree; stdcall;
    function GetDropTargetHelperSupported: Boolean; stdcall;
    function GetIsDropTarget: Boolean; stdcall;

    property DataObject: IDataObject read GetDataObject;
    property DragSource: TBaseVirtualTree read GetDragSource;
    property DropTargetHelperSupported: Boolean read GetDropTargetHelperSupported;
    property IsDropTarget: Boolean read GetIsDropTarget;
  end;
  
  TVTDataObject = class(TInterfacedObject, IDataObject)
  private
    FOwner: TBaseVirtualTree;          
    FForClipboard: Boolean;            
    FFormatEtcArray: TFormatEtcArray;
    FInternalStgMediumArray: TInternalStgMediumArray;  
    FAdviseHolder: IDataAdviseHolder;  
  protected
    function CanonicalIUnknown(TestUnknown: IUnknown): IUnknown;
    function EqualFormatEtc(FormatEtc1, FormatEtc2: TFormatEtc): Boolean;
    function FindFormatEtc(TestFormatEtc: TFormatEtc; const FormatEtcArray: TFormatEtcArray): integer;
    function FindInternalStgMedium(Format: TClipFormat): PStgMedium;
    function HGlobalClone(HGlobal: THandle): THandle;
    function RenderInternalOLEData(const FormatEtcIn: TFormatEtc; var Medium: TStgMedium; var OLEResult: HResult): Boolean;
    function StgMediumIncRef(const InStgMedium: TStgMedium; var OutStgMedium: TStgMedium;
      CopyInMedium: Boolean; DataObject: IDataObject): HRESULT;

    property ForClipboard: Boolean read FForClipboard;
    property FormatEtcArray: TFormatEtcArray read FFormatEtcArray write FFormatEtcArray;
    property InternalStgMediumArray: TInternalStgMediumArray read FInternalStgMediumArray write FInternalStgMediumArray;
    property Owner: TBaseVirtualTree read FOwner;
  public
    constructor Create(AOwner: TBaseVirtualTree; ForClipboard: Boolean); virtual;
    destructor Destroy; override;

    function DAdvise(const FormatEtc: TFormatEtc; advf: Integer; const advSink: IAdviseSink; out dwConnection: Integer):
      HResult; virtual; stdcall;
    function DUnadvise(dwConnection: Integer): HResult; virtual; stdcall;
    function EnumDAdvise(out enumAdvise: IEnumStatData): HResult; virtual; stdcall;
    function EnumFormatEtc(Direction: Integer; out EnumFormatEtc: IEnumFormatEtc): HResult; virtual; stdcall;
    function GetCanonicalFormatEtc(const FormatEtc: TFormatEtc; out FormatEtcOut: TFormatEtc): HResult; virtual; stdcall;
    function GetData(const FormatEtcIn: TFormatEtc; out Medium: TStgMedium): HResult; virtual; stdcall;
    function GetDataHere(const FormatEtc: TFormatEtc; out Medium: TStgMedium): HResult; virtual; stdcall;
    function QueryGetData(const FormatEtc: TFormatEtc): HResult; virtual; stdcall;
    function SetData(const FormatEtc: TFormatEtc; var Medium: TStgMedium; DoRelease: BOOL): HResult; virtual; stdcall;
  end;
  
  TVTDragManager = class(TInterfacedObject, IVTDragManager, IDropSource, IDropTarget)
  private
    FOwner,                            
    FDragSource: TBaseVirtualTree;     
                                       
    FIsDropTarget: Boolean;            
    FDataObject: IDataObject;          
                                       
    FDropTargetHelper: IDropTargetHelper; 
    FFullDragging: BOOL;               

    function GetDataObject: IDataObject; stdcall;
    function GetDragSource: TBaseVirtualTree; stdcall;
    function GetDropTargetHelperSupported: Boolean; stdcall;
    function GetIsDropTarget: Boolean; stdcall;
  public
    constructor Create(AOwner: TBaseVirtualTree); virtual;
    destructor Destroy; override;

    function DragEnter(const DataObject: IDataObject; KeyState: Integer; Pt: TPoint;
      var Effect: Longint): HResult; stdcall;
    function DragLeave: HResult; stdcall;
    function DragOver(KeyState: Integer; Pt: TPoint; var Effect: LongInt): HResult; stdcall;
    function Drop(const DataObject: IDataObject; KeyState: Integer; Pt: TPoint; var Effect: Integer): HResult; stdcall;
    procedure ForceDragLeave; stdcall;
    function GiveFeedback(Effect: Integer): HResult; stdcall;
    function QueryContinueDrag(EscapePressed: BOOL; KeyState: Integer): HResult; stdcall;
  end;

  PVTHintData = ^TVTHintData;
  TVTHintData = record
    Tree: TBaseVirtualTree;
    Node: PVirtualNode;
    Column: TColumnIndex;
    HintRect: TRect;            
    DefaultHint: UnicodeString; 
                                
    HintText: UnicodeString;    
    BidiMode: TBidiMode;
    Alignment: TAlignment;
    LineBreakStyle: TVTToolTipLineBreakStyle;
  end;
  
  THintAnimationType = (
    hatNone,                 
    hatFade,                 
    hatSlide,                
    hatSystemDefault         
  );
  
  TVirtualTreeHintWindow = class(THintWindow)
  private
    FHintData: TVTHintData;
    FBackground,
    FDrawBuffer,
    FTarget: TBitmap;
    FTextHeight: Integer;
    function AnimationCallback(Step, StepSize: Integer; Data: Pointer): Boolean;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    function GetHintWindowDestroyed: Boolean;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMNCPaint(var Message: TMessage); message WM_NCPAINT;
    procedure WMShowWindow(var Message: TWMShowWindow); message WM_SHOWWINDOW;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure InternalPaint(Step, StepSize: Integer);
    procedure Paint; override;

    property Background: TBitmap read FBackground;
    property DrawBuffer: TBitmap read FDrawBuffer;
    property HintData: TVTHintData read FHintData;
    property HintWindowDestroyed: Boolean read GetHintWindowDestroyed;
    property Target: TBitmap read FTarget;
    property TextHeight: Integer read FTextHeight;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ActivateHint(Rect: TRect; const AHint: string); override;
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect; override;
    function IsHintMsg(var Msg: TMsg): Boolean; override;
  end;
  
  TVTTransparency = 0..255;
  TVTBias = -128..127;
  
  TVTDragMoveRestriction = (
    dmrNone,
    dmrHorizontalOnly,
    dmrVerticalOnly
  );

  TVTDragImageStates = set of (
    disHidden,          
    disInDrag,          
    disPrepared,        
    disSystemSupport    
  );
  
  TVTDragImage = class
  private
    FOwner: TBaseVirtualTree;
    FBackImage,                        
    FAlphaImage,                       
    FDragImage: TBitmap;               
    FImagePosition,                    
    FLastPosition: TPoint;             
    FTransparency: TVTTransparency;    
    FPreBlendBias,                     
    FPostBlendBias: TVTBias;           
    FFade: Boolean;                    
    FRestriction: TVTDragMoveRestriction;  
    FColorKey: TColor;                 
    FStates: TVTDragImageStates;       
    function GetVisible: Boolean;      
  protected
    procedure InternalShowDragImage(ScreenDC: HDC);
    procedure MakeAlphaChannel(Source, Target: TBitmap);
  public
    constructor Create(AOwner: TBaseVirtualTree);
    destructor Destroy; override;

    function DragTo(P: TPoint; ForceRepaint: Boolean): Boolean;
    procedure EndDrag;
    function GetDragImageRect: TRect;
    procedure HideDragImage;
    procedure PrepareDrag(DragImage: TBitmap; ImagePosition, HotSpot: TPoint; const DataObject: IDataObject);
    procedure RecaptureBackground(Tree: TBaseVirtualTree; R: TRect; VisibleRegion: HRGN; CaptureNCArea,
      ReshowDragImage: Boolean);
    procedure ShowDragImage;
    function WillMove(P: TPoint): Boolean;

    property ColorKey: TColor read FColorKey write FColorKey default clWindow;
    property Fade: Boolean read FFade write FFade default False;
    property MoveRestriction: TVTDragMoveRestriction read FRestriction write FRestriction default dmrNone;
    property PostBlendBias: TVTBias read FPostBlendBias write FPostBlendBias default 0;
    property PreBlendBias: TVTBias read FPreBlendBias write FPreBlendBias default 0;
    property Transparency: TVTTransparency read FTransparency write FTransparency default 128;
    property Visible: Boolean read GetVisible;
  end;
  
  TVirtualTreeColumns = class;
  TVTHeader = class;

  TVirtualTreeColumnStyle = (
    vsText,
    vsOwnerDraw
  );

  TVTHeaderColumnLayout = (
    blGlyphLeft,
    blGlyphRight,
    blGlyphTop,
    blGlyphBottom
  );

  TSortDirection = (
    sdAscending,
    sdDescending
  );

  TVirtualTreeColumn = class(TCollectionItem)
  private
    FText,
    FHint: UnicodeString;
    FLeft,
    FWidth: Integer;
    FPosition: TColumnPosition;
    FMinWidth: Integer;
    FMaxWidth: Integer;
    FStyle: TVirtualTreeColumnStyle;
    FImageIndex: TImageIndex;
    FBiDiMode: TBiDiMode;
    FLayout: TVTHeaderColumnLayout;
    FMargin,
    FSpacing: Integer;
    FOptions: TVTColumnOptions;
    FTag: Integer;
    FAlignment: TAlignment;
    FCaptionAlignment: TAlignment;     
    FLastWidth: Integer;
    FColor: TColor;
    FBonusPixel: Boolean;
    FSpringRest: Single;               
    FCaptionText: UnicodeString;
    FCheckBox: Boolean;
    FCheckType: TCheckType;
    FCheckState: TCheckState;
    FImageRect: TRect;
    FHasImage: Boolean;
    fDefaultSortDirection: TSortDirection;
    function GetCaptionAlignment: TAlignment;
    function GetLeft: Integer;
    function IsBiDiModeStored: Boolean;
    function IsCaptionAlignmentStored: Boolean;
    function IsColorStored: Boolean;
    procedure SetAlignment(const Value: TAlignment);
    procedure SetBiDiMode(Value: TBiDiMode);
    procedure SetCaptionAlignment(const Value: TAlignment);
    procedure SetCheckBox(Value: Boolean);
    procedure SetCheckState(Value: TCheckState);
    procedure SetCheckType(Value: TCheckType);
    procedure SetColor(const Value: TColor);
    procedure SetImageIndex(Value: TImageIndex);
    procedure SetLayout(Value: TVTHeaderColumnLayout);
    procedure SetMargin(Value: Integer);
    procedure SetMaxWidth(Value: Integer);
    procedure SetMinWidth(Value: Integer);
    procedure SetOptions(Value: TVTColumnOptions);
    procedure SetPosition(Value: TColumnPosition);
    procedure SetSpacing(Value: Integer);
    procedure SetStyle(Value: TVirtualTreeColumnStyle);
    procedure SetText(const Value: UnicodeString);
    procedure SetWidth(Value: Integer);
  protected
    procedure ComputeHeaderLayout(DC: HDC; Client: TRect; UseHeaderGlyph, UseSortGlyph: Boolean;
      var HeaderGlyphPos, SortGlyphPos: TPoint; var SortGlyphSize: TSize; var TextBounds: TRect; DrawFormat: Cardinal;
      CalculateTextRect: Boolean = False);
    procedure DefineProperties(Filer: TFiler); override;
    procedure GetAbsoluteBounds(var Left, Right: Integer);
    function GetDisplayName: string; override;
    function GetOwner: TVirtualTreeColumns; reintroduce;
    procedure ReadHint(Reader: TReader);
    procedure ReadText(Reader: TReader);
    procedure WriteHint(Writer: TWriter);
    procedure WriteText(Writer: TWriter);
    property HasImage: Boolean read fHasImage;
    property ImageRect: TRect read fImageRect;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
{$if CompilerVersion >= 20}
   function Equals(OtherColumnObj: TObject): Boolean; override;
{$else}
   function Equals(OtherColumnObj: TObject): Boolean;
{$ifend}
    function GetRect: TRect; virtual;
    procedure LoadFromStream(const Stream: TStream; Version: Integer);
    procedure ParentBiDiModeChanged;
    procedure ParentColorChanged;
    procedure RestoreLastWidth;
    procedure SaveToStream(const Stream: TStream);
    function UseRightToLeftReading: Boolean;

    property Left: Integer read GetLeft;
    property Owner: TVirtualTreeColumns read GetOwner;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property BiDiMode: TBiDiMode read FBiDiMode write SetBiDiMode stored IsBiDiModeStored;
    property CaptionAlignment: TAlignment read GetCaptionAlignment write SetCaptionAlignment
      stored IsCaptionAlignmentStored default taLeftJustify;
    property CaptionText: UnicodeString read FCaptionText stored False;
    property CheckType: TCheckType read FCheckType write SetCheckType default ctCheckBox;
    property CheckState: TCheckState read FCheckState write SetCheckState default csUncheckedNormal;
    property CheckBox: Boolean read FCheckBox write SetCheckBox default False;
    property Color: TColor read FColor write SetColor stored IsColorStored;
    property DefaultSortDirection: TSortDirection read fDefaultSortDirection write fDefaultSortDirection default sdAscending;
    property Hint: UnicodeString read FHint write FHint stored False;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property Layout: TVTHeaderColumnLayout read FLayout write SetLayout default blGlyphLeft;
    property Margin: Integer read FMargin write SetMargin default 4;
    property MaxWidth: Integer read FMaxWidth write SetMaxWidth default 10000;
    property MinWidth: Integer read FMinWidth write SetMinWidth default 10;
    property Options: TVTColumnOptions read FOptions write SetOptions default DefaultColumnOptions;
    property Position: TColumnPosition read FPosition write SetPosition;
    property Spacing: Integer read FSpacing write SetSpacing default 3;
    property Style: TVirtualTreeColumnStyle read FStyle write SetStyle default vsText;
    property Tag: Integer read FTag write FTag default 0;
    property Text: UnicodeString read FText write SetText stored False; 
                                                                     
    property Width: Integer read FWidth write SetWidth default 50;
  end;

  TVirtualTreeColumnClass = class of TVirtualTreeColumn;

  TColumnsArray = array of TVirtualTreeColumn;
  TCardinalArray = array of Cardinal;
  TIndexArray = array of TColumnIndex;

  TVirtualTreeColumns = class(TCollection)
  private
    FHeader: TVTHeader;
    FHeaderBitmap: TBitmap;               
    FHoverIndex,                          
    FDownIndex,                           
    FTrackIndex: TColumnIndex;            
    FClickIndex: TColumnIndex;            
    FCheckBoxHit: Boolean;                
    FPositionToIndex: TIndexArray;
    FDefaultWidth: Integer;               
    FNeedPositionsFix: Boolean;           
    FClearing: Boolean;                   

    function GetCount: Integer;
    function GetItem(Index: TColumnIndex): TVirtualTreeColumn;
    function GetNewIndex(P: TPoint; var OldIndex: TColumnIndex): Boolean;
    procedure SetDefaultWidth(Value: Integer);
    procedure SetItem(Index: TColumnIndex; Value: TVirtualTreeColumn);
  protected
    
    FDragIndex: TColumnIndex;             
    FDropTarget: TColumnIndex;            
    FDropBefore: Boolean;                 

    procedure AdjustAutoSize(CurrentIndex: TColumnIndex; Force: Boolean = False);
    function AdjustDownColumn(P: TPoint): TColumnIndex;
    function AdjustHoverColumn(P: TPoint): Boolean;
    procedure AdjustPosition(Column: TVirtualTreeColumn; Position: Cardinal);
    function CanSplitterResize(P: TPoint; Column: TColumnIndex): Boolean;
    procedure DoCanSplitterResize(P: TPoint; Column: TColumnIndex; var Allowed: Boolean); virtual;
    procedure DrawButtonText(DC: HDC; Caption: UnicodeString; Bounds: TRect; Enabled, Hot: Boolean; DrawFormat: Cardinal;
      WrapCaption: Boolean);
    procedure FixPositions;
    function GetColumnAndBounds(P: TPoint; var ColumnLeft, ColumnRight: Integer; Relative: Boolean = True): Integer;
    function GetOwner: TPersistent; override;
    procedure HandleClick(P: TPoint; Button: TMouseButton; Force, DblClick: Boolean); virtual;
    procedure IndexChanged(OldIndex, NewIndex: Integer);
    procedure InitializePositionArray;
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
    procedure ReorderColumns(RTL: Boolean);
    procedure Update(Item: TCollectionItem); override;
    procedure UpdatePositions(Force: Boolean = False);

    property HeaderBitmap: TBitmap read FHeaderBitmap;
    property PositionToIndex: TIndexArray read FPositionToIndex;
    property HoverIndex: TColumnIndex read FHoverIndex;
    property DownIndex: TColumnIndex read FDownIndex;
    property CheckBoxHit: Boolean read FCheckBoxHit;
  public
    constructor Create(AOwner: TVTHeader); virtual;
    destructor Destroy; override;

    function Add: TVirtualTreeColumn; virtual;
    procedure AnimatedResize(Column: TColumnIndex; NewWidth: Integer);
    procedure Assign(Source: TPersistent); override;
    procedure Clear; virtual;
    function ColumnFromPosition(P: TPoint; Relative: Boolean = True): TColumnIndex; overload; virtual;
    function ColumnFromPosition(PositionIndex: TColumnPosition): TColumnIndex; overload; virtual;
{$if CompilerVersion >= 20}
   function Equals(OtherColumnsObj: TObject): Boolean; override;
{$else}
   function Equals(OtherColumnsObj: TObject): Boolean;
{$ifend}
    procedure GetColumnBounds(Column: TColumnIndex; var Left, Right: Integer);
    function GetFirstVisibleColumn(ConsiderAllowFocus: Boolean = False): TColumnIndex;
    function GetLastVisibleColumn(ConsiderAllowFocus: Boolean = False): TColumnIndex;
    function GetFirstColumn: TColumnIndex;
    function GetNextColumn(Column: TColumnIndex): TColumnIndex;
    function GetNextVisibleColumn(Column: TColumnIndex; ConsiderAllowFocus: Boolean = False): TColumnIndex;
    function GetPreviousColumn(Column: TColumnIndex): TColumnIndex;
    function GetPreviousVisibleColumn(Column: TColumnIndex; ConsiderAllowFocus: Boolean = False): TColumnIndex;
    function GetScrollWidth: Integer;
    function GetVisibleColumns: TColumnsArray;
    function GetVisibleFixedWidth: Integer;
    function IsValidColumn(Column: TColumnIndex): Boolean;
    procedure LoadFromStream(const Stream: TStream; Version: Integer);
    procedure PaintHeader(DC: HDC; R: TRect; HOffset: Integer); overload; virtual;
    procedure PaintHeader(TargetCanvas: TCanvas; R: TRect; const Target: TPoint;
      RTLOffset: Integer = 0); overload; virtual;
    procedure SaveToStream(const Stream: TStream);
    function TotalWidth: Integer;

    property Count: Integer read GetCount;
    property ClickIndex: TColumnIndex read FClickIndex;
    property DefaultWidth: Integer read FDefaultWidth write SetDefaultWidth default 50;
    property Items[Index: TColumnIndex]: TVirtualTreeColumn read GetItem write SetItem; default;
    property Header: TVTHeader read FHeader;
    property TrackIndex: TColumnIndex read FTrackIndex;
  end;

  TVirtualTreeColumnsClass = class of TVirtualTreeColumns;

  TVTConstraintPercent = 0..100;
  TVTFixedAreaConstraints = class(TPersistent)
  private
    FHeader: TVTHeader;
    FMaxHeightPercent,
    FMaxWidthPercent,
    FMinHeightPercent,
    FMinWidthPercent: TVTConstraintPercent;
    FOnChange: TNotifyEvent;
    procedure SetConstraints(Index: Integer; Value: TVTConstraintPercent);
  protected
    procedure Change;
    property Header: TVTHeader read FHeader;
  public
    constructor Create(AOwner: TVTHeader);

    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property MaxHeightPercent: TVTConstraintPercent index 0 read FMaxHeightPercent write SetConstraints default 0;
    property MaxWidthPercent: TVTConstraintPercent index 1 read FMaxWidthPercent write SetConstraints default 0;
    property MinHeightPercent: TVTConstraintPercent index 2 read FMinHeightPercent write SetConstraints default 0;
    property MinWidthPercent: TVTConstraintPercent index 3 read FMinWidthPercent write SetConstraints default 0;
  end;

  TVTHeaderStyle = (
    hsThickButtons,    
    hsFlatButtons,     
    hsPlates          
  );

  TVTHeaderOption = (
    hoAutoResize,            
    hoColumnResize,          
    hoDblClickResize,        
    hoDrag,                  
    hoHotTrack,              
    hoOwnerDraw,             
    hoRestrictDrag,          
    hoShowHint,              
    hoShowImages,            
    hoShowSortGlyphs,        
    hoVisible,               
    hoAutoSpring,            
                             
    hoFullRepaintOnResize,   
    hoDisableAnimatedResize, 
    hoHeightResize,          
    hoHeightDblClickResize,  
    hoHeaderClickAutoSort    
                             
  );
  TVTHeaderOptions = set of TVTHeaderOption;

  THeaderState = (
    hsAutoSizing,              
    hsDragging,                
    hsDragPending,             
    hsLoading,                 
    hsColumnWidthTracking,     
    hsColumnWidthTrackPending, 
    hsHeightTracking,          
    hsHeightTrackPending,      
    hsResizing,                
    hsScaling,                 
    hsNeedScaling              
  );
  THeaderStates = set of THeaderState;

  TSmartAutoFitType = (
    smaAllColumns,      
    smaNoColumn,        
    smaUseColumnOption  
  );  

  TChangeReason = (
    crIgnore,       
    crAccumulated,  
    crChildAdded,   
    crChildDeleted, 
    crNodeAdded,    
    crNodeCopied,   
    crNodeMoved     
  ); 

  TVTHeader = class(TPersistent)
  private
    FOwner: TBaseVirtualTree;
    FColumns: TVirtualTreeColumns;
    FHeight: Integer;
    FFont: TFont;
    FParentFont: Boolean;
    FOptions: TVTHeaderOptions;
    FStyle: TVTHeaderStyle;            
    FBackground: TColor;
    FAutoSizeIndex: TColumnIndex;
    FPopupMenu: TPopupMenu;
    FMainColumn: TColumnIndex;         
    FMaxHeight: Integer;
    FMinHeight: Integer;
    FDefaultHeight: Integer;
    FFixedAreaConstraints: TVTFixedAreaConstraints; 
    FImages: TCustomImageList;
    FImageChangeLink: TChangeLink;     
    FSortColumn: TColumnIndex;
    FSortDirection: TSortDirection;
    FDragImage: TVTDragImage;          
    FLastWidth: Integer;               
                                       
    procedure FontChanged(Sender: TObject);
    function GetMainColumn: TColumnIndex;
    function GetUseColumns: Boolean;
    function IsFontStored: Boolean;
    procedure SetAutoSizeIndex(Value: TColumnIndex);
    procedure SetBackground(Value: TColor);
    procedure SetColumns(Value: TVirtualTreeColumns);
    procedure SetDefaultHeight(Value: Integer);
    procedure SetFont(const Value: TFont);
    procedure SetHeight(Value: Integer);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetMainColumn(Value: TColumnIndex);
    procedure SetMaxHeight(Value: Integer);
    procedure SetMinHeight(Value: Integer);
    procedure SetOptions(Value: TVTHeaderOptions);
    procedure SetParentFont(Value: Boolean);
    procedure SetSortColumn(Value: TColumnIndex);
    procedure SetSortDirection(const Value: TSortDirection);
    procedure SetStyle(Value: TVTHeaderStyle);
  protected
    FStates: THeaderStates;            
    FDragStart: TPoint;                
    FTrackStart: TPoint;               
    FTrackPoint: TPoint;               
    
    function CanSplitterResize(P: TPoint): Boolean;
    function CanWriteColumns: Boolean; virtual;
    procedure ChangeScale(M, D: Integer); virtual;
    function DetermineSplitterIndex(P: TPoint): Boolean; virtual;
    procedure DoAfterAutoFitColumn(Column: TColumnIndex); virtual;
    procedure DoAfterColumnWidthTracking(Column: TColumnIndex); virtual;
    procedure DoAfterHeightTracking; virtual;
    function DoBeforeAutoFitColumn(Column: TColumnIndex; SmartAutoFitType: TSmartAutoFitType): Boolean; virtual;
    procedure DoBeforeColumnWidthTracking(Column: TColumnIndex; Shift: TShiftState); virtual;
    procedure DoBeforeHeightTracking(Shift: TShiftState); virtual;
    procedure DoCanSplitterResize(P: TPoint; var Allowed: Boolean); virtual;
    function DoColumnWidthDblClickResize(Column: TColumnIndex; P: TPoint; Shift: TShiftState): Boolean; virtual;
    function DoColumnWidthTracking(Column: TColumnIndex; Shift: TShiftState; var TrackPoint: TPoint; P: TPoint): Boolean; virtual;
    function DoGetPopupMenu(Column: TColumnIndex; Position: TPoint): TPopupMenu; virtual;
    function DoHeightTracking(var P: TPoint; Shift: TShiftState): Boolean; virtual;
    function DoHeightDblClickResize(var P: TPoint; Shift: TShiftState): Boolean; virtual;
    procedure DoSetSortColumn(Value: TColumnIndex); virtual;
    procedure DragTo(P: TPoint);
    procedure FixedAreaConstraintsChanged(Sender: TObject);
    function GetColumnsClass: TVirtualTreeColumnsClass; virtual;
    function GetOwner: TPersistent; override;
    function GetShiftState: TShiftState;
    function HandleHeaderMouseMove(var Message: TWMMouseMove): Boolean;
    function HandleMessage(var Message: TMessage): Boolean; virtual;
    procedure ImageListChange(Sender: TObject);
    procedure PrepareDrag(P, Start: TPoint);
    procedure ReadColumns(Reader: TReader);
    procedure RecalculateHeader; virtual;
    procedure RescaleHeader;
    procedure UpdateMainColumn;
    procedure UpdateSpringColumns;
    procedure WriteColumns(Writer: TWriter);
  public
    constructor Create(AOwner: TBaseVirtualTree); virtual;
    destructor Destroy; override;

    function AllowFocus(ColumnIndex: TColumnIndex): Boolean;
    procedure Assign(Source: TPersistent); override;
    procedure AutoFitColumns(Animated: Boolean = True; SmartAutoFitType: TSmartAutoFitType = smaUseColumnOption;
      RangeStartCol: Integer = NoColumn; RangeEndCol: Integer = NoColumn); virtual;
    function InHeader(P: TPoint): Boolean; virtual;
    function InHeaderSplitterArea(P: TPoint): Boolean; virtual;
    procedure Invalidate(Column: TVirtualTreeColumn; ExpandToBorder: Boolean = False);
    procedure LoadFromStream(const Stream: TStream); virtual;
    function ResizeColumns(ChangeBy: Integer; RangeStartCol: TColumnIndex; RangeEndCol: TColumnIndex;
      Options: TVTColumnOptions = [coVisible]): Integer;
    procedure RestoreColumns;
    procedure SaveToStream(const Stream: TStream); virtual;

    property DragImage: TVTDragImage read FDragImage;
    property States: THeaderStates read FStates;
    property Treeview: TBaseVirtualTree read FOwner;
    property UseColumns: Boolean read GetUseColumns;
  published
    property AutoSizeIndex: TColumnIndex read FAutoSizeIndex write SetAutoSizeIndex;
    property Background: TColor read FBackground write SetBackground default clBtnFace;
    property Columns: TVirtualTreeColumns read FColumns write SetColumns stored False; 
    property DefaultHeight: Integer read FDefaultHeight write SetDefaultHeight default 19;
    property Font: TFont read FFont write SetFont stored IsFontStored;
    property FixedAreaConstraints: TVTFixedAreaConstraints read FFixedAreaConstraints write FFixedAreaConstraints;
    property Height: Integer read FHeight write SetHeight default 19;
    property Images: TCustomImageList read FImages write SetImages;
    property MainColumn: TColumnIndex read GetMainColumn write SetMainColumn default 0;
    property MaxHeight: Integer read FMaxHeight write SetMaxHeight default 10000;
    property MinHeight: Integer read FMinHeight write SetMinHeight default 10;
    property Options: TVTHeaderOptions read FOptions write SetOptions default [hoColumnResize, hoDrag, hoShowSortGlyphs];
    property ParentFont: Boolean read FParentFont write SetParentFont default False;
    property PopupMenu: TPopupMenu read FPopupMenu write FPopUpMenu;
    property SortColumn: TColumnIndex read FSortColumn write SetSortColumn default NoColumn;
    property SortDirection: TSortDirection read FSortDirection write SetSortDirection default sdAscending;
    property Style: TVTHeaderStyle read FStyle write SetStyle default hsThickButtons;
  end;

  TVTHeaderClass = class of TVTHeader;
  
  IVTEditLink = interface
    ['{2BE3EAFA-5ACB-45B4-9D9A-B58BCC496E17}']
    function BeginEdit: Boolean; stdcall;                  
    function CancelEdit: Boolean; stdcall;                 
    function EndEdit: Boolean; stdcall;                    
    function PrepareEdit(Tree: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex): Boolean; stdcall;
                                                           
    function GetBounds: TRect; stdcall;                    
                                                           
    procedure ProcessMessage(var Message: TMessage); stdcall;
                                                           
    procedure SetBounds(R: TRect); stdcall;                
  end;
  
  TVTUpdateState = (
    usBegin,       
    usBeginSynch,  
    usSynch,       
    usUpdate,      
    usEnd,         
    usEndSynch     
  );
  
  TVTDropMarkMode = (
    dmmNone,
    dmmLeft,
    dmmRight
  );
  
  THeaderPaintInfo = record
    TargetCanvas: TCanvas;
    Column: TVirtualTreeColumn;
    PaintRectangle: TRect;
    TextRectangle: TRect;
    IsHoverIndex,
    IsDownIndex,
    IsEnabled,
    ShowHeaderGlyph,
    ShowSortGlyph,
    ShowRightBorder: Boolean;
    DropMark: TVTDropMarkMode;
    GlyphPos,
    SortGlyphPos: TPoint;
  end;
  
  THeaderPaintElements = set of (
    hpeBackground,
    hpeDropMark,
    hpeHeaderGlyph,
    hpeSortGlyph,
    hpeText
  );
  
  TVirtualTreeStates = set of (
    tsCancelHintAnimation,    
    tsChangePending,          
    tsCheckPropagation,       
    tsCollapsing,             
    tsToggleFocusedSelection, 
    tsClearPending,           
    tsClipboardFlushing,      
    tsCopyPending,            
    tsCutPending,             
    tsDrawSelPending,         
                              
    tsDrawSelecting,          
    tsEditing,                
    tsEditPending,            
    tsExpanding,              
    tsNodeHeightTracking,     
    tsNodeHeightTrackPending, 
    tsHint,                   
    tsInAnimation,            
    tsIncrementalSearching,   
    tsIncrementalSearchPending, 
    tsIterating,              
    tsKeyCheckPending,        
    tsLeftButtonDown,         
    tsLeftDblClick,           
    tsMouseCheckPending,      
    tsMiddleButtonDown,       
    tsMiddleDblClick,         
    tsNeedRootCountUpdate,    
    tsOLEDragging,            
    tsOLEDragPending,         
    tsPainting,               
    tsRightButtonDown,        
    tsRightDblClick,          
    tsPopupMenuShown,         
    tsScrolling,              
    tsScrollPending,          
    tsSizing,                 
                              
    tsStopValidation,         
    tsStructureChangePending, 
    tsSynchMode,              
    tsThumbTracking,          
    tsToggling,               
    tsUpdateHiddenChildrenNeeded, 
    tsUpdating,               
    tsUseCache,               
    tsUserDragObject,         
    tsUseThemes,              
    tsValidating,             
    tsValidationNeeded,       
    tsVCLDragging,            
    tsVCLDragPending,         
    tsVCLDragFinished,        
    tsWheelPanning,           
    tsWheelScrolling,         
    tsWindowCreating,         
    tsUseExplorerTheme        
  );

  TChangeStates = set of (
    csStopValidation,         
    csUseCache,               
    csValidating,             
    csValidationNeeded        
  );
  
  TVTDragImageKind = (
    diComplete,       
    diMainColumnOnly, 
    diNoImage         
  );
  
  TVTDragType = (
    dtOLE,
    dtVCL
  );
  
  TVTInternalPaintOption = (
    poBackground,       
    poColumnColor,      
    poDrawFocusRect,    
    poDrawSelection,    
    poDrawDropMark,     
    poGridLines,        
    poMainOnly,         
    poSelectedOnly,     
    poUnbuffered        
  );
  TVTInternalPaintOptions = set of TVTInternalPaintOption;
  
  TVTLineStyle = (
    lsCustomStyle,           
    lsDotted,                
    lsSolid                  
  );
  
  TVTLineType = (
    ltNone,          
    ltBottomRight,   
    ltTopDown,       
    ltTopDownRight,  
    ltRight,         
    ltTopRight,      
    
    ltLeft,          
    ltLeftBottom     
  );
  
  TVTLineMode = (
    lmNormal,        
    lmBands          
  );
  
  TLineImage = array of TVTLineType;

  TVTScrollIncrement = 1..10000;
  
  TVTExportType = (
    etRTF,   
    etHTML,  
    etText,  
    etExcel, 
    etWord,  
    etCustom 
  );

  TVTNodeExportEvent   = function (Sender: TBaseVirtualTree; aExportType: TVTExportType; Node: PVirtualNode): Boolean of object;
  TVTColumnExportEvent = procedure (Sender: TBaseVirtualTree; aExportType: TVTExportType; Column: TVirtualTreeColumn) of object;
  TVTTreeExportEvent   = procedure(Sender: TBaseVirtualTree; aExportType: TVTExportType) of object;
  
  TScrollBarOptions = class(TPersistent)
  private
    FAlwaysVisible: Boolean;
    FOwner: TBaseVirtualTree;
    FScrollBars: TScrollStyle;                   
    FScrollBarStyle: TScrollBarStyle;            
    FIncrementX,
    FIncrementY: TVTScrollIncrement;             
    procedure SetAlwaysVisible(Value: Boolean);
    procedure SetScrollBars(Value: TScrollStyle);
    procedure SetScrollBarStyle(Value: TScrollBarStyle);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TBaseVirtualTree);

    procedure Assign(Source: TPersistent); override;
  published
    property AlwaysVisible: Boolean read FAlwaysVisible write SetAlwaysVisible default False;
    property HorizontalIncrement: TVTScrollIncrement read FIncrementX write FIncrementX default 20;
    property ScrollBars: TScrollStyle read FScrollbars write SetScrollBars default ssBoth;
    property ScrollBarStyle: TScrollBarStyle read FScrollBarStyle write SetScrollBarStyle default sbmRegular;
    property VerticalIncrement: TVTScrollIncrement read FIncrementY write FIncrementY default 20;
  end;
  
  TVTColors = class(TPersistent)
  private
    FOwner: TBaseVirtualTree;
    FColors: array[0..15] of TColor;
    function GetColor(const Index: Integer): TColor;
    procedure SetColor(const Index: Integer; const Value: TColor);
    function GetBackgroundColor: TColor;
    function GetHeaderFontColor: TColor;
    function GetNodeFontColor: TColor;
  public
    constructor Create(AOwner: TBaseVirtualTree);

    procedure Assign(Source: TPersistent); override;
    property BackGroundColor: TColor read GetBackgroundColor;
    property HeaderFontColor: TColor read  GetHeaderFontColor;
    property NodeFontColor: TColor read GetNodeFontColor;
  published
    property BorderColor: TColor index 7 read GetColor write SetColor default clBtnFace;
    property DisabledColor: TColor index 0 read GetColor write SetColor default clBtnShadow;
    property DropMarkColor: TColor index 1 read GetColor write SetColor default clHighlight;
    property DropTargetColor: TColor index 2 read GetColor write SetColor default clHighLight;
    property DropTargetBorderColor: TColor index 11 read GetColor write SetColor default clHighLight;
    property FocusedSelectionColor: TColor index 3 read GetColor write SetColor default clHighLight;
    property FocusedSelectionBorderColor: TColor index 9 read GetColor write SetColor default clHighLight;
    property GridLineColor: TColor index 4 read GetColor write SetColor default clBtnFace;
    property HeaderHotColor: TColor index 14 read GetColor write SetColor default clBtnShadow;
    property HotColor: TColor index 8 read GetColor write SetColor default clWindowText;
    property SelectionRectangleBlendColor: TColor index 12 read GetColor write SetColor default clHighlight;
    property SelectionRectangleBorderColor: TColor index 13 read GetColor write SetColor default clHighlight;
    property SelectionTextColor: TColor index 15 read GetColor write SetColor default clHighlightText;
    property TreeLineColor: TColor index 5 read GetColor write SetColor default clBtnShadow;
    property UnfocusedSelectionColor: TColor index 6 read GetColor write SetColor default clBtnFace;
    property UnfocusedSelectionBorderColor: TColor index 10 read GetColor write SetColor default clBtnFace;
  end;
  
  TVTImageInfo = record
    Index: Integer;           
    XPos,                     
    YPos: Integer;            
    Ghosted: Boolean;         
    Images: TCustomImageList; 
  end;

  TVTImageInfoIndex = (
    iiNormal,
    iiState,
    iiCheck,
    iiOverlay
  );
  
  TScrollUpdateOptions = set of (
    suoRepaintHeader,        
    suoRepaintScrollbars,    
    suoScrollClientArea,     
    suoUpdateNCArea          
  );
  
  TVTButtonStyle = (
    bsRectangle,             
    bsTriangle               
  );
  
  TVTButtonFillMode = (
    fmTreeColor,             
    fmWindowColor,           
    fmShaded,                
    fmTransparent            
  );

  TVTPaintInfo = record
    Canvas: TCanvas;              
    PaintOptions: TVTInternalPaintOptions;  
    Node: PVirtualNode;           
    Column: TColumnIndex;         
    Position: TColumnPosition;    
    CellRect,                     
    ContentRect: TRect;           
    NodeWidth: Integer;           
    Alignment: TAlignment;        
    CaptionAlignment: TAlignment; 
    BidiMode: TBidiMode;          
    BrushOrigin: TPoint;          
    ImageInfo: array[TVTImageInfoIndex] of TVTImageInfo; 
  end;
  
  TVTAnimationCallback = function(Step, StepSize: Integer; Data: Pointer): Boolean of object;

  TVTIncrementalSearch = (
    isAll,                   
    isNone,                  
    isInitializedOnly,       
    isVisibleOnly            
  );
  
  TVTSearchDirection = (
    sdForward,
    sdBackward
  );
  
  TVTSearchStart = (
    ssAlwaysStartOver,       
    ssLastHit,               
    ssFocusedNode            
  );
  
  TVTNodeAlignment = (
    naFromBottom,            
    naFromTop,               
    naProportional           
  );
  
  TVTDrawSelectionMode = (
    smDottedRectangle,       
    smBlendedRectangle       
  );
  
  TVTCellPaintMode = (
    cpmPaint,                
    cpmGetContentMargin      
  );
  
  TVTCellContentMarginType = (
    ccmtAllSides,            
    ccmtTopLeftOnly,         
    ccmtBottomRightOnly      
  );

  TClipboardFormats = class(TStringList)
  private
    FOwner: TBaseVirtualTree;
  public
    constructor Create(AOwner: TBaseVirtualTree); virtual;

    function Add(const S: string): Integer; override;
    procedure Insert(Index: Integer; const S: string); override;
    property Owner: TBaseVirtualTree read FOwner;
  end;
  
  {$if CompilerVersion >= 20}
  TVTGetNodeProc = reference to procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Data: Pointer; var Abort: Boolean);
  {$else}
  TVTGetNodeProc = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Data: Pointer; var Abort: Boolean) of object;
  {$ifend}
  
  TVTChangingEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; var Allowed: Boolean) of object;
  TVTCheckChangingEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; var NewState: TCheckState;
    var Allowed: Boolean) of object;
  TVTChangeEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode) of object;
  TVTStructureChangeEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Reason: TChangeReason) of object;
  TVTEditCancelEvent = procedure(Sender: TBaseVirtualTree; Column: TColumnIndex) of object;
  TVTEditChangingEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
    var Allowed: Boolean) of object;
  TVTEditChangeEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex) of object;
  TVTFreeNodeEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode) of object;
  TVTFocusChangingEvent = procedure(Sender: TBaseVirtualTree; OldNode, NewNode: PVirtualNode; OldColumn,
    NewColumn: TColumnIndex; var Allowed: Boolean) of object;
  TVTFocusChangeEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex) of object;
  TVTAddToSelectionEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode) of object;
  TVTRemoveFromSelectionEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode) of object;
  TVTGetImageEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
    var Ghosted: Boolean; var ImageIndex: Integer) of object;
  TVTGetImageExEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
    var Ghosted: Boolean; var ImageIndex: Integer; var ImageList: TCustomImageList) of object;
  TVTGetImageTextEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
    var ImageText: UnicodeString) of object;
  TVTHotNodeChangeEvent = procedure(Sender: TBaseVirtualTree; OldNode, NewNode: PVirtualNode) of object;
  TVTInitChildrenEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; var ChildCount: Cardinal) of object;
  TVTInitNodeEvent = procedure(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode;
    var InitialStates: TVirtualNodeInitStates) of object;
  TVTPopupEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; const P: TPoint;
    var AskParent: Boolean; var PopupMenu: TPopupMenu) of object;
  TVTHelpContextEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
    var HelpContext: Integer) of object;
  TVTCreateEditorEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
    out EditLink: IVTEditLink) of object;
  TVTSaveTreeEvent = procedure(Sender: TBaseVirtualTree; Stream: TStream) of object;
  TVTSaveNodeEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Stream: TStream) of object;
  
  TVTHeaderClickEvent = procedure(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo) of object;
  TVTHeaderMouseEvent = procedure(Sender: TVTHeader; Button: TMouseButton; Shift: TShiftState; X, Y: Integer) of object;
  TVTHeaderMouseMoveEvent = procedure(Sender: TVTHeader; Shift: TShiftState; X, Y: Integer) of object;
  TVTBeforeHeaderHeightTrackingEvent = procedure(Sender: TVTHeader; Shift: TShiftState) of object;
  TVTAfterHeaderHeightTrackingEvent = procedure(Sender: TVTHeader) of object;
  TVTHeaderHeightTrackingEvent = procedure(Sender: TVTHeader; var P: TPoint; Shift: TShiftState; var Allowed: Boolean) of object;
  TVTHeaderHeightDblClickResizeEvent = procedure(Sender: TVTHeader; var P: TPoint; Shift: TShiftState; var Allowed: Boolean) of object;
  TVTHeaderNotifyEvent = procedure(Sender: TVTHeader; Column: TColumnIndex) of object;
  TVTHeaderDraggingEvent = procedure(Sender: TVTHeader; Column: TColumnIndex; var Allowed: Boolean) of object;
  TVTHeaderDraggedEvent = procedure(Sender: TVTHeader; Column: TColumnIndex; OldPosition: Integer) of object;
  TVTHeaderDraggedOutEvent = procedure(Sender: TVTHeader; Column: TColumnIndex; DropPosition: TPoint) of object;
  TVTHeaderPaintEvent = procedure(Sender: TVTHeader; HeaderCanvas: TCanvas; Column: TVirtualTreeColumn; R: TRect; Hover,
    Pressed: Boolean; DropMark: TVTDropMarkMode) of object;
  TVTHeaderPaintQueryElementsEvent = procedure(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo;
    var Elements: THeaderPaintElements) of object;
  TVTAdvancedHeaderPaintEvent = procedure(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo;
    const Elements: THeaderPaintElements) of object;
  TVTBeforeAutoFitColumnsEvent = procedure(Sender: TVTHeader; var SmartAutoFitType: TSmartAutoFitType) of object;
  TVTBeforeAutoFitColumnEvent = procedure(Sender: TVTHeader; Column: TColumnIndex; var SmartAutoFitType: TSmartAutoFitType;
    var Allowed: Boolean) of object;
  TVTAfterAutoFitColumnEvent = procedure(Sender: TVTHeader; Column: TColumnIndex) of object;
  TVTAfterAutoFitColumnsEvent = procedure(Sender: TVTHeader) of object;
  TVTColumnClickEvent = procedure (Sender: TBaseVirtualTree; Column: TColumnIndex; Shift: TShiftState) of object;
  TVTColumnDblClickEvent = procedure (Sender: TBaseVirtualTree; Column: TColumnIndex; Shift: TShiftState) of object;
  TVTColumnWidthDblClickResizeEvent = procedure(Sender: TVTHeader; Column: TColumnIndex; Shift: TShiftState; P: TPoint;
    var Allowed: Boolean) of object;
  TVTBeforeColumnWidthTrackingEvent = procedure(Sender: TVTHeader; Column: TColumnIndex; Shift: TShiftState) of object;
  TVTAfterColumnWidthTrackingEvent = procedure(Sender: TVTHeader; Column: TColumnIndex) of object;
  TVTColumnWidthTrackingEvent = procedure(Sender: TVTHeader; Column: TColumnIndex; Shift: TShiftState; var TrackPoint: TPoint; P: TPoint;
    var Allowed: Boolean) of object;
  TVTGetHeaderCursorEvent = procedure(Sender: TVTHeader; var Cursor: HCURSOR) of object;
  TVTBeforeGetMaxColumnWidthEvent = procedure(Sender: TVTHeader; Column: TColumnIndex; var UseSmartColumnWidth: Boolean) of object;
  TVTAfterGetMaxColumnWidthEvent = procedure(Sender: TVTHeader; Column: TColumnIndex; var MaxWidth: Integer) of object;
  TVTCanSplitterResizeColumnEvent = procedure(Sender: TVTHeader; P: TPoint; Column: TColumnIndex; var Allowed: Boolean) of object;
  TVTCanSplitterResizeHeaderEvent = procedure(SendeR: TVTHeader; P: TPoint; var Allowed: Boolean) of object;
  
  TVTNodeMovedEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode) of object;
  TVTNodeMovingEvent = procedure(Sender: TBaseVirtualTree; Node, Target: PVirtualNode;
    var Allowed: Boolean) of object;
  TVTNodeCopiedEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode) of object;
  TVTNodeCopyingEvent = procedure(Sender: TBaseVirtualTree; Node, Target: PVirtualNode;
    var Allowed: Boolean) of object;
  TVTNodeClickEvent = procedure(Sender: TBaseVirtualTree; const HitInfo: THitInfo) of object;
  TVTNodeHeightTrackingEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; Shift: TShiftState;
    var TrackPoint: TPoint; P: TPoint; var Allowed: Boolean) of object;
  TVTNodeHeightDblClickResizeEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
    Shift: TShiftState; P: TPoint; var Allowed: Boolean) of object;
  TVTCanSplitterResizeNodeEvent = procedure(Sender: TBaseVirtualTree; P: TPoint; Node: PVirtualNode;
    Column: TColumnIndex; var Allowed: Boolean) of object;
  
  TVTCreateDragManagerEvent = procedure(Sender: TBaseVirtualTree; out DragManager: IVTDragManager) of object;
  TVTCreateDataObjectEvent = procedure(Sender: TBaseVirtualTree; out IDataObject: IDataObject) of object;
  TVTDragAllowedEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
    var Allowed: Boolean) of object;
  TVTDragOverEvent = procedure(Sender: TBaseVirtualTree; Source: TObject; Shift: TShiftState; State: TDragState;
    Pt: TPoint; Mode: TDropMode; var Effect: Integer; var Accept: Boolean) of object;
  TVTDragDropEvent = procedure(Sender: TBaseVirtualTree; Source: TObject; DataObject: IDataObject;
    Formats: TFormatArray; Shift: TShiftState; Pt: TPoint; var Effect: Integer; Mode: TDropMode) of object;
  TVTRenderOLEDataEvent = procedure(Sender: TBaseVirtualTree; const FormatEtcIn: TFormatEtc; out Medium: TStgMedium;
    ForClipboard: Boolean; var Result: HRESULT) of object;
  TVTGetUserClipboardFormatsEvent = procedure(Sender: TBaseVirtualTree; var Formats: TFormatEtcArray) of object;
  
  TVTBeforeItemEraseEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
    var ItemColor: TColor; var EraseAction: TItemEraseAction) of object;
  TVTAfterItemEraseEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
    ItemRect: TRect) of object;
  TVTBeforeItemPaintEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
    ItemRect: TRect; var CustomDraw: Boolean) of object;
  TVTAfterItemPaintEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
    ItemRect: TRect) of object;
  TVTBeforeCellPaintEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
    Column: TColumnIndex; CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect) of object;
  TVTAfterCellPaintEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
    Column: TColumnIndex; CellRect: TRect) of object;
  TVTPaintEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas) of object;
  TVTBackgroundPaintEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; R: TRect;
    var Handled: Boolean) of object;
  TVTGetLineStyleEvent = procedure(Sender: TBaseVirtualTree; var Bits: Pointer) of object;
  TVTMeasureItemEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
    var NodeHeight: Integer) of object;
  
  TVTCompareEvent = procedure(Sender: TBaseVirtualTree; Node1, Node2: PVirtualNode; Column: TColumnIndex;
    var Result: Integer) of object;
  TVTIncrementalSearchEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; const SearchText: UnicodeString;
    var Result: Integer) of object;
  
  TVTOperationEvent = procedure(Sender: TBaseVirtualTree; OperationKind: TVTOperationKind) of object;

  TVTHintKind = (vhkText, vhkOwnerDraw);
  TVTHintKindEvent = procedure(sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var Kind: TVTHintKind) of object;
  TVTDrawHintEvent = procedure(Sender: TBaseVirtualTree; HintCanvas: TCanvas; Node: PVirtualNode; R: TRect; Column: TColumnIndex) of object;
  TVTGetHintSizeEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var R: TRect) of object;
  
  TVTBeforeDrawLineImageEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Level: Integer; var PosX: Integer) of object;
  TVTGetNodeDataSizeEvent = procedure(Sender: TBaseVirtualTree; var NodeDataSize: Integer) of object;
  TVTKeyActionEvent = procedure(Sender: TBaseVirtualTree; var CharCode: Word; var Shift: TShiftState;
    var DoDefault: Boolean) of object;
  TVTScrollEvent = procedure(Sender: TBaseVirtualTree; DeltaX, DeltaY: Integer) of object;
  TVTUpdatingEvent = procedure(Sender: TBaseVirtualTree; State: TVTUpdateState) of object;
  TVTGetCursorEvent = procedure(Sender: TBaseVirtualTree; var Cursor: TCursor) of object;
  TVTStateChangeEvent = procedure(Sender: TBaseVirtualTree; Enter, Leave: TVirtualTreeStates) of object;
  TVTGetCellIsEmptyEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
    var IsEmpty: Boolean) of object;
  TVTScrollbarShowEvent = procedure(Sender: TBaseVirtualTree; Bar: Integer; Show: Boolean) of object;
  
  TGetFirstNodeProc = function: PVirtualNode of object;
  TGetNextNodeProc = function(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode of object;

  TVZVirtualNodeEnumerationMode = (
    vneAll,
    vneChecked,
    vneChild,
    vneCutCopy,
    vneInitialized,
    vneLeaf,
    vneLevel,
    vneNoInit,
    vneSelected,
    vneVisible,
    vneVisibleChild,
    vneVisibleNoInitChild,
    vneVisibleNoInit
  );

  PVTVirtualNodeEnumeration = ^TVTVirtualNodeEnumeration;

  TVTVirtualNodeEnumerator = {$if CompilerVersion >= 18}record{$else}class{$ifend}
  private
    FNode: PVirtualNode;
    FCanModeNext: Boolean;
    FEnumeration: PVTVirtualNodeEnumeration;
    function GetCurrent: PVirtualNode; {$if CompilerVersion >= 18}inline;{$ifend}
  public
    function MoveNext: Boolean; {$if CompilerVersion >= 18}inline;{$ifend}
    property Current: PVirtualNode read GetCurrent;
  end;

  TVTVirtualNodeEnumeration = {$if CompilerVersion >= 18}record{$else}object{$ifend}
  private
    FMode: TVZVirtualNodeEnumerationMode;
    FTree: TBaseVirtualTree;
    
    FConsiderChildrenAbove: Boolean;
    FNode: PVirtualNode;
    FNodeLevel: Cardinal;
    FState: TCheckState;
    FIncludeFiltered: Boolean;
  public
    function GetEnumerator: TVTVirtualNodeEnumerator;
  private
    function GetNext(Node: PVirtualNode): PVirtualNode;
  end;
  
{$if CompilerVersion >= 23 }
  TVclStyleScrollBarsHook = class(TMouseTrackControlStyleHook)
  strict private type
  {$REGION 'TVclStyleScrollBarWindow'}
      TVclStyleScrollBarWindow = class(TWinControl)strict private FScrollBarWindowOwner: TVclStyleScrollBarsHook;
    FScrollBarVertical: Boolean;
    FScrollBarVisible: Boolean;
    FScrollBarEnabled: Boolean;
    procedure WMNCHitTest(var Msg: TWMNCHitTest);
    message WM_NCHITTEST;
    procedure WMEraseBkgnd(var Msg: TMessage);
    message WM_ERASEBKGND;
    procedure WMPaint(var Msg: TWMPaint);
    message WM_PAINT;
  strict protected
    procedure CreateParams(var Params: TCreateParams);
    override;
  public
    constructor Create(AOwner: TComponent);
    override;
    property ScrollBarWindowOwner: TVclStyleScrollBarsHook read FScrollBarWindowOwner write FScrollBarWindowOwner;
    property ScrollBarVertical: Boolean read FScrollBarVertical write FScrollBarVertical;
    property ScrollBarVisible: Boolean read FScrollBarVisible write FScrollBarVisible;
    property ScrollBarEnabled: Boolean read FScrollBarEnabled write FScrollBarEnabled;
    end;
  {$ENDREGION}
  private
    FHorzScrollBarDownButtonRect: TRect;
    FHorzScrollBarDownButtonState: TThemedScrollBar;
    FHorzScrollBarRect: TRect;
    FHorzScrollBarSliderState: TThemedScrollBar;
    FHorzScrollBarSliderTrackRect: TRect;
    FHorzScrollBarUpButtonRect: TRect;
    FHorzScrollBarUpButtonState: TThemedScrollBar;
    FHorzScrollBarWindow: TVclStyleScrollBarWindow;
    FLeftMouseButtonDown: Boolean;
    FPrevScrollPos: Integer;
    FScrollPos: Single;
    FVertScrollBarDownButtonRect: TRect;
    FVertScrollBarDownButtonState: TThemedScrollBar;
    FVertScrollBarRect: TRect;
    FVertScrollBarSliderState: TThemedScrollBar;
    FVertScrollBarSliderTrackRect: TRect;
    FVertScrollBarUpButtonRect: TRect;
    FVertScrollBarUpButtonState: TThemedScrollBar;
    FVertScrollBarWindow: TVclStyleScrollBarWindow;

    procedure WMKeyDown(var Msg: TMessage);
    message WM_KEYDOWN;
    procedure WMKeyUp(var Msg: TMessage);
    message WM_KEYUP;
    procedure WMLButtonDown(var Msg: TWMMouse);
    message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var Msg: TWMMouse);
    message WM_LBUTTONUP;
    procedure WMNCLButtonDown(var Msg: TWMMouse);
    message WM_NCLBUTTONDOWN;
    procedure WMNCMouseMove(var Msg: TWMMouse);
    message WM_NCMOUSEMOVE;
    procedure WMNCLButtonUp(var Msg: TWMMouse);
    message WM_NCLBUTTONUP;
    procedure WMNCPaint(var Msg: TMessage);
    message WM_NCPAINT;
    procedure WMMouseMove(var Msg: TWMMouse);
    message WM_MOUSEMOVE;
    procedure WMMouseWheel(var Msg: TMessage);
    message WM_MOUSEWHEEL;
    procedure WMVScroll(var Msg: TMessage);
    message WM_VSCROLL;
    procedure WMHScroll(var Msg: TMessage);
    message WM_HSCROLL;
    procedure WMCaptureChanged(var Msg: TMessage);
    message WM_CAPTURECHANGED;
    procedure WMNCLButtonDblClk(var Msg: TWMMouse);
    message WM_NCLBUTTONDBLCLK;
    procedure WMSize(var Msg: TMessage);
    message WM_SIZE;
  protected
    procedure CalcScrollBarsRect; virtual;
    procedure DrawHorzScrollBar(DC: HDC); virtual;
    procedure DrawVertScrollBar(DC: HDC); virtual;
    function GetHorzScrollBarSliderRect: TRect;
    function GetVertScrollBarSliderRect: TRect;
    procedure MouseLeave; override;
    procedure PaintScrollBars; virtual;
    function PointInTreeHeader(const P: TPoint): Boolean;
    procedure UpdateScrollBarWindow;
  public
    constructor Create(AControl: TWinControl); override;
    destructor Destroy; override;
  end;
{$ifend}
  
  TBaseVirtualTree = class(TCustomControl)
  private
    FBorderStyle: TBorderStyle;
    FHeader: TVTHeader;
    FRoot: PVirtualNode;
    FDefaultNodeHeight,
    FIndent: Cardinal;
    FOptions: TCustomVirtualTreeOptions;
    FUpdateCount: Cardinal;                      
    FSynchUpdateCount: Cardinal;                 
                                                 
    FNodeDataSize: Integer;                      
                                                 
    FStates: TVirtualTreeStates;                 
    FLastSelected,
    FFocusedNode: PVirtualNode;
    FEditColumn,                                 
    FFocusedColumn: TColumnIndex;                
                                                 
    FHeightTrackPoint: TPoint;                   
    FHeightTrackNode: PVirtualNode;              
    FHeightTrackColumn: TColumnIndex;            
    FScrollDirections: TScrollDirections;        
    FLastStructureChangeReason: TChangeReason;   
    FLastStructureChangeNode,                    
    FLastChangedNode,                            
    FCurrentHotNode: PVirtualNode;               
    FCurrentHotColumn: TColumnIndex;             
    FHotNodeButtonHit: Boolean;                  
    FLastSelRect,
    FNewSelRect: TRect;                          
    FHotCursor: TCursor;                         
    FAnimationType: THintAnimationType;          
                                                 
    FHintMode: TVTHintMode;                      
    FHintData: TVTHintData;                      
    FChangeDelay: Cardinal;                      
    FEditDelay: Cardinal;                        
    FPositionCache: TCache;                      
                                                 
    FVisibleCount: Cardinal;                     
    FStartIndex: Cardinal;                       
    FSelection: TNodeArray;                      
    FSelectionCount: Integer;                    
    FSelectionLocked: Boolean;                   
    FRangeAnchor: PVirtualNode;                  
                                                 
    FCheckNode: PVirtualNode;                    
    FPendingCheckState: TCheckState;             
    FCheckPropagationCount: Cardinal;            
    FLastSelectionLevel: Integer;                
    FDrawSelShiftState: TShiftState;             
                                                 
    FEditLink: IVTEditLink;                      
    FTempNodeCache: TNodeArray;                  
    FTempNodeCount: Cardinal;                    
    FBackground: TPicture;                       
    FMargin: Integer;                            
    FTextMargin: Integer;                        
    FBackgroundOffsetX,
    FBackgroundOffsetY: Integer;                 
    FAnimationDuration: Cardinal;                
    FWantTabs: Boolean;                          
    FNodeAlignment: TVTNodeAlignment;            
    FHeaderRect: TRect;                          
    FLastHintRect: TRect;                        
    FUpdateRect: TRect;
    FEmptyListMessage: UnicodeString;            
    
    FPlusBM,
    FMinusBM,                                    
    FHotPlusBM,
    FHotMinusBM: TBitmap;                        
    FImages,                                     
    FStateImages,                                
    FCustomCheckImages: TCustomImageList;        
    FCheckImageKind: TCheckImageKind;            
    FCheckImages: TCustomImageList;              
    FImageChangeLink,
    FStateChangeLink,
    FCustomCheckChangeLink: TChangeLink;         
    FOldFontChange: TNotifyEvent;                
    FFontChanged: Boolean;                       
    FColors: TVTColors;                          
    FButtonStyle: TVTButtonStyle;                
    FButtonFillMode: TVTButtonFillMode;          
    FLineStyle: TVTLineStyle;                    
    FLineMode: TVTLineMode;                      
    FDottedBrush: HBRUSH;                        
    FSelectionCurveRadius: Cardinal;             
    FSelectionBlendFactor: Byte;                 
                                                 
    FDrawSelectionMode: TVTDrawSelectionMode;    
    
    FAlignment: TAlignment;                      
    
    FDragImageKind: TVTDragImageKind;            
    FDragOperations: TDragOperations;            
    FDragThreshold: Integer;                     
    FDragManager: IVTDragManager;                
    FDropTargetNode: PVirtualNode;               
    FLastDropMode: TDropMode;                    
    FDragSelection: TNodeArray;                  
    FLastDragEffect: LongInt;                    
    FDragType: TVTDragType;                      
    FDragImage: TVTDragImage;                    
    FDragWidth,
    FDragHeight: Integer;                        
    FClipboardFormats: TClipboardFormats;        
    FLastVCLDragTarget: PVirtualNode;            
    FVCLDragEffect: Integer;                     
    
    FScrollBarOptions: TScrollBarOptions;        
    FAutoScrollInterval: TAutoScrollInterval;    
    FAutoScrollDelay: Cardinal;                  
    FAutoExpandDelay: Cardinal;                  
                                                 
    FOffsetX: Integer;
    FOffsetY: Integer;                           
    FEffectiveOffsetX: Integer;                  
    FRangeX,
    FRangeY: Cardinal;                           
    FBottomSpace: Cardinal;                      

    FDefaultPasteMode: TVTNodeAttachMode;        
    FSingletonNodeArray: TNodeArray;             
                                                 
    FDragScrollStart: Cardinal;                  
    
    FIncrementalSearch: TVTIncrementalSearch;    
    FSearchTimeout: Cardinal;                    
    FSearchBuffer: UnicodeString;                 
    FLastSearchNode: PVirtualNode;               
    FSearchDirection: TVTSearchDirection;        
    FSearchStart: TVTSearchStart;                
    
    FTotalInternalDataSize: Cardinal;            
                                                 
    FPanningWindow: HWND;                        
    FPanningCursor: HCURSOR;                     
    FPanningImage: TBitmap;                      
    FLastClickPos: TPoint;                       
    FOperationCount: Cardinal;                   
    FOperationCanceled: Boolean;                 
    FChangingTheme: Boolean;                     
    
    FAccessible: IAccessible;                    
    FAccessibleItem: IAccessible;                
    FAccessibleName: string;                     
    
    FOnBeforeNodeExport: TVTNodeExportEvent;     
    FOnNodeExport: TVTNodeExportEvent;
    FOnAfterNodeExport: TVTNodeExportEvent;      
    FOnBeforeColumnExport: TVTColumnExportEvent; 
    FOnColumnExport: TVTColumnExportEvent;
    FOnAfterColumnExport: TVTColumnExportEvent;  
    FOnBeforeTreeExport: TVTTreeExportEvent;     
    FOnAfterTreeExport: TVTTreeExportEvent;      
    FOnBeforeHeaderExport: TVTTreeExportEvent;   
    FOnAfterHeaderExport: TVTTreeExportEvent;    
    
    FOnChange: TVTChangeEvent;                   
    FOnStructureChange: TVTStructureChangeEvent; 
    FOnInitChildren: TVTInitChildrenEvent;       
    FOnInitNode: TVTInitNodeEvent;               
    FOnFreeNode: TVTFreeNodeEvent;               
                                                 
    FOnGetImage: TVTGetImageEvent;               
    FOnGetImageEx: TVTGetImageExEvent;           
                                                 
    FOnGetImageText: TVTGetImageTextEvent;       
                                                 
    FOnHotChange: TVTHotNodeChangeEvent;         
                                                 
    FOnExpanding,                                
    FOnCollapsing: TVTChangingEvent;             
    FOnChecking: TVTCheckChangingEvent;          
    FOnExpanded,                                 
    FOnCollapsed,                                
    FOnChecked: TVTChangeEvent;                  
    FOnResetNode: TVTChangeEvent;                
    FOnNodeMoving: TVTNodeMovingEvent;           
                                                 
    FOnNodeMoved: TVTNodeMovedEvent;             
                                                 
    FOnNodeCopying: TVTNodeCopyingEvent;         
                                                 
    FOnNodeClick: TVTNodeClickEvent;             
    FOnNodeDblClick: TVTNodeClickEvent;          
    FOnCanSplitterResizeNode: TVTCanSplitterResizeNodeEvent;       
    FOnNodeHeightTracking: TVTNodeHeightTrackingEvent;             
    FOnNodeHeightDblClickResize: TVTNodeHeightDblClickResizeEvent; 
    FOnNodeCopied: TVTNodeCopiedEvent;           
    FOnEditing: TVTEditChangingEvent;            
    FOnEditCancelled: TVTEditCancelEvent;        
    FOnEdited: TVTEditChangeEvent;               
    FOnFocusChanging: TVTFocusChangingEvent;     
                                                 
    FOnFocusChanged: TVTFocusChangeEvent;        
    FOnAddToSelection: TVTAddToSelectionEvent;           
    FOnRemoveFromSelection: TVTRemoveFromSelectionEvent; 
    FOnGetPopupMenu: TVTPopupEvent;              
    FOnGetHelpContext: TVTHelpContextEvent;      
    FOnCreateEditor: TVTCreateEditorEvent;       
                                                 
    FOnLoadNode,                                 
                                                 
    FOnSaveNode: TVTSaveNodeEvent;               
                                                 
    FOnLoadTree,                                 
                                                 
    FOnSaveTree: TVTSaveTreeEvent;               
    
    FOnAfterAutoFitColumn: TVTAfterAutoFitColumnEvent;
    FOnAfterAutoFitColumns: TVTAfterAutoFitColumnsEvent;
    FOnBeforeAutoFitColumns: TVTBeforeAutoFitColumnsEvent;
    FOnBeforeAutoFitColumn: TVTBeforeAutoFitColumnEvent;
    FOnHeaderClick: TVTHeaderClickEvent;
    FOnHeaderDblClick: TVTHeaderClickEvent;
    FOnAfterHeaderHeightTracking: TVTAfterHeaderHeightTrackingEvent;
    FOnBeforeHeaderHeightTracking: TVTBeforeHeaderHeightTrackingEvent;
    FOnHeaderHeightTracking: TVTHeaderHeightTrackingEvent;
    FOnHeaderHeightDblClickResize: TVTHeaderHeightDblClickResizeEvent;
    FOnHeaderMouseDown,
    FOnHeaderMouseUp: TVTHeaderMouseEvent;
    FOnHeaderMouseMove: TVTHeaderMouseMoveEvent;
    FOnAfterGetMaxColumnWidth: TVTAfterGetMaxColumnWidthEvent;
    FOnBeforeGetMaxColumnWidth: TVTBeforeGetMaxColumnWidthEvent;
    FOnColumnClick: TVTColumnClickEvent;
    FOnColumnDblClick: TVTColumnDblClickEvent;
    FOnColumnResize: TVTHeaderNotifyEvent;
    FOnColumnWidthDblClickResize: TVTColumnWidthDblClickResizeEvent;
    FOnAfterColumnWidthTracking: TVTAfterColumnWidthTrackingEvent;
    FOnBeforeColumnWidthTracking: TVTBeforeColumnWidthTrackingEvent;
    FOnColumnWidthTracking: TVTColumnWidthTrackingEvent;
    FOnGetHeaderCursor: TVTGetHeaderCursorEvent; 
    FOnCanSplitterResizeColumn: TVTCanSplitterResizeColumnEvent;
    FOnCanSplitterResizeHeader: TVTCanSplitterResizeHeaderEvent;
    
    FOnAfterPaint,                               
    FOnBeforePaint: TVTPaintEvent;               
    FOnAfterItemPaint: TVTAfterItemPaintEvent;   
    FOnBeforeItemPaint: TVTBeforeItemPaintEvent; 
    FOnBeforeItemErase: TVTBeforeItemEraseEvent; 
    FOnAfterItemErase: TVTAfterItemEraseEvent;   
    FOnAfterCellPaint: TVTAfterCellPaintEvent;   
    FOnBeforeCellPaint: TVTBeforeCellPaintEvent; 
    FOnHeaderDraw: TVTHeaderPaintEvent;          
                                                 
    FOnHeaderDrawQueryElements: TVTHeaderPaintQueryElementsEvent; 
                                                 
    FOnAdvancedHeaderDraw: TVTAdvancedHeaderPaintEvent; 
                                                 
    FOnGetLineStyle: TVTGetLineStyleEvent;       
                                                 
    FOnPaintBackground: TVTBackgroundPaintEvent; 
                                                 
    FOnMeasureItem: TVTMeasureItemEvent;         
    
    FOnCreateDragManager: TVTCreateDragManagerEvent; 
    FOnCreateDataObject: TVTCreateDataObjectEvent; 
    FOnDragAllowed: TVTDragAllowedEvent;         
    FOnDragOver: TVTDragOverEvent;               
    FOnDragDrop: TVTDragDropEvent;               
    FOnHeaderDragged: TVTHeaderDraggedEvent;     
    FOnHeaderDraggedOut: TVTHeaderDraggedOutEvent; 
    FOnHeaderDragging: TVTHeaderDraggingEvent;   
    FOnRenderOLEData: TVTRenderOLEDataEvent;     
    FOnGetUserClipboardFormats: TVTGetUserClipboardFormatsEvent; 
    
    FOnGetNodeDataSize: TVTGetNodeDataSizeEvent; 
    FOnBeforeDrawLineImage: TVTBeforeDrawLineImageEvent; 
    FOnKeyAction: TVTKeyActionEvent;             
    FOnScroll: TVTScrollEvent;                   
    FOnUpdating: TVTUpdatingEvent;               
    FOnGetCursor: TVTGetCursorEvent;             
    FOnStateChange: TVTStateChangeEvent;         
    FOnGetCellIsEmpty: TVTGetCellIsEmptyEvent;   
    FOnShowScrollbar: TVTScrollbarShowEvent;     
    
    FOnCompareNodes: TVTCompareEvent;            
    FOnDrawHint: TVTDrawHintEvent;
    FOnGetHintSize: TVTGetHintSizeEvent;
    fOnGetHintKind: TVTHintKindEvent;
    FOnIncrementalSearch: TVTIncrementalSearchEvent; 
    FOnMouseEnter: TNotifyEvent;
    FOnMouseLeave: TNotifyEvent;
    
    FOnStartOperation: TVTOperationEvent;        
    FOnEndOperation: TVTOperationEvent;          

    FVclStyleEnabled: Boolean;

    {$if CompilerVersion >= 23 }
    FSavedBevelKind: TBevelKind;
    FSavedBorderWidth: Integer;
    FSetOrRestoreBevelKindAndBevelWidth: Boolean;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure CMBorderChanged(var Message: TMessage); message CM_BORDERCHANGED;
    procedure CMParentDoubleBufferedChange(var Message: TMessage); message CM_PARENTDOUBLEBUFFEREDCHANGED;
    {$ifend}

    procedure AdjustCoordinatesByIndent(var PaintInfo: TVTPaintInfo; Indent: Integer);
    procedure AdjustTotalCount(Node: PVirtualNode; Value: Integer; relative: Boolean = False);
    procedure AdjustTotalHeight(Node: PVirtualNode; Value: Integer; relative: Boolean = False);
    function CalculateCacheEntryCount: Integer;
    procedure CalculateVerticalAlignments(ShowImages, ShowStateImages: Boolean; Node: PVirtualNode; var VAlign,
      VButtonAlign: Integer);
    function ChangeCheckState(Node: PVirtualNode; Value: TCheckState): Boolean;
    function CollectSelectedNodesLTR(MainColumn, NodeLeft, NodeRight: Integer; Alignment: TAlignment; OldRect,
      NewRect: TRect): Boolean;
    function CollectSelectedNodesRTL(MainColumn, NodeLeft, NodeRight: Integer; Alignment: TAlignment; OldRect,
      NewRect: TRect): Boolean;
    procedure ClearNodeBackground(const PaintInfo: TVTPaintInfo; UseBackground, Floating: Boolean; R: TRect);
    function CompareNodePositions(Node1, Node2: PVirtualNode; ConsiderChildrenAbove: Boolean = False): Integer;
    procedure DrawLineImage(const PaintInfo: TVTPaintInfo; X, Y, H, VAlign: Integer; Style: TVTLineType; Reverse: Boolean);
    function FindInPositionCache(Node: PVirtualNode; var CurrentPos: Cardinal): PVirtualNode; overload;
    function FindInPositionCache(Position: Cardinal; var CurrentPos: Cardinal): PVirtualNode; overload;
    procedure FixupTotalCount(Node: PVirtualNode);
    procedure FixupTotalHeight(Node: PVirtualNode);
    function GetBottomNode: PVirtualNode;
    function GetCheckedCount: Integer;
    function GetCheckState(Node: PVirtualNode): TCheckState;
    function GetCheckType(Node: PVirtualNode): TCheckType;
    function GetChildCount(Node: PVirtualNode): Cardinal;
    function GetChildrenInitialized(Node: PVirtualNode): Boolean;
    function GetCutCopyCount: Integer;
    function GetDisabled(Node: PVirtualNode): Boolean;
    function GetDragManager: IVTDragManager;
    function GetExpanded(Node: PVirtualNode): Boolean;
    function GetFiltered(Node: PVirtualNode): Boolean;
    function GetFullyVisible(Node: PVirtualNode): Boolean;
    function GetHasChildren(Node: PVirtualNode): Boolean;
    function GetMultiline(Node: PVirtualNode): Boolean;
    function GetNodeHeight(Node: PVirtualNode): Cardinal;
    function GetNodeParent(Node: PVirtualNode): PVirtualNode;
    function GetOffsetXY: TPoint;
    function GetRootNodeCount: Cardinal;
    function GetSelected(Node: PVirtualNode): Boolean;
    function GetTopNode: PVirtualNode;
    function GetTotalCount: Cardinal;
    function GetVerticalAlignment(Node: PVirtualNode): Byte;
    function GetVisible(Node: PVirtualNode): Boolean;
    function GetVisiblePath(Node: PVirtualNode): Boolean;
    procedure HandleClickSelection(LastFocused, NewNode: PVirtualNode; Shift: TShiftState; DragPending: Boolean);
    function HandleDrawSelection(X, Y: Integer): Boolean;
    function HasVisibleNextSibling(Node: PVirtualNode): Boolean;
    function HasVisiblePreviousSibling(Node: PVirtualNode): Boolean;
    procedure ImageListChange(Sender: TObject);
    procedure InitializeFirstColumnValues(var PaintInfo: TVTPaintInfo);
    procedure InitRootNode(OldSize: Cardinal = 0);
    procedure InterruptValidation;
    function IsFirstVisibleChild(Parent, Node: PVirtualNode): Boolean;
    function IsLastVisibleChild(Parent, Node: PVirtualNode): Boolean;
    function MakeNewNode: PVirtualNode;
    function PackArray(const TheArray: TNodeArray; Count: Integer): Integer;
    procedure PrepareBitmaps(NeedButtons, NeedLines: Boolean);
    procedure ReadOldOptions(Reader: TReader);
    procedure SetAlignment(const Value: TAlignment);
    procedure SetAnimationDuration(const Value: Cardinal);
    procedure SetBackground(const Value: TPicture);
    procedure SetBackgroundOffset(const Index, Value: Integer);
    procedure SetBorderStyle(Value: TBorderStyle);
    procedure SetBottomNode(Node: PVirtualNode);
    procedure SetBottomSpace(const Value: Cardinal);
    procedure SetButtonFillMode(const Value: TVTButtonFillMode);
    procedure SetButtonStyle(const Value: TVTButtonStyle);
    procedure SetCheckImageKind(Value: TCheckImageKind);
    procedure SetCheckState(Node: PVirtualNode; Value: TCheckState);
    procedure SetCheckType(Node: PVirtualNode; Value: TCheckType);
    procedure SetChildCount(Node: PVirtualNode; NewChildCount: Cardinal);
    procedure SetClipboardFormats(const Value: TClipboardFormats);
    procedure SetColors(const Value: TVTColors);
    procedure SetCustomCheckImages(const Value: TCustomImageList);
    procedure SetDefaultNodeHeight(Value: Cardinal);
    procedure SetDisabled(Node: PVirtualNode; Value: Boolean);
    procedure SetEmptyListMessage(const Value: UnicodeString);
    procedure SetExpanded(Node: PVirtualNode; Value: Boolean);
    procedure SetFocusedColumn(Value: TColumnIndex);
    procedure SetFocusedNode(Value: PVirtualNode);
    procedure SetFullyVisible(Node: PVirtualNode; Value: Boolean);
    procedure SetHasChildren(Node: PVirtualNode; Value: Boolean);
    procedure SetHeader(const Value: TVTHeader);
    procedure SetFiltered(Node: PVirtualNode; Value: Boolean);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetIndent(Value: Cardinal);
    procedure SetLineMode(const Value: TVTLineMode);
    procedure SetLineStyle(const Value: TVTLineStyle);
    procedure SetMargin(Value: Integer);
    procedure SetMultiline(Node: PVirtualNode; const Value: Boolean);
    procedure SetNodeAlignment(const Value: TVTNodeAlignment);
    procedure SetNodeDataSize(Value: Integer);
    procedure SetNodeHeight(Node: PVirtualNode; Value: Cardinal);
    procedure SetNodeParent(Node: PVirtualNode; const Value: PVirtualNode);
    procedure SetOffsetX(const Value: Integer);
    procedure SetOffsetXY(const Value: TPoint);
    procedure SetOffsetY(const Value: Integer);
    procedure SetOptions(const Value: TCustomVirtualTreeOptions);
    procedure SetRootNodeCount(Value: Cardinal);
    procedure SetScrollBarOptions(Value: TScrollBarOptions);
    procedure SetSearchOption(const Value: TVTIncrementalSearch);
    procedure SetSelected(Node: PVirtualNode; Value: Boolean);
    procedure SetSelectionCurveRadius(const Value: Cardinal);
    procedure SetStateImages(const Value: TCustomImageList);
    procedure SetTextMargin(Value: Integer);
    procedure SetTopNode(Node: PVirtualNode);
    procedure SetUpdateState(Updating: Boolean);
    procedure SetVerticalAlignment(Node: PVirtualNode; Value: Byte);
    procedure SetVisible(Node: PVirtualNode; Value: Boolean);
    procedure SetVisiblePath(Node: PVirtualNode; Value: Boolean);
    procedure StaticBackground(Source: TBitmap; Target: TCanvas; OffsetPosition: TPoint; R: TRect);
    procedure StopTimer(ID: Integer);
    procedure SetWindowTheme(Theme: Unicodestring);
    procedure TileBackground(Source: TBitmap; Target: TCanvas; Offset: TPoint; R: TRect);
    function ToggleCallback(Step, StepSize: Integer; Data: Pointer): Boolean;

    procedure CMColorChange(var Message: TMessage); message CM_COLORCHANGED;
    procedure CMCtl3DChanged(var Message: TMessage); message CM_CTL3DCHANGED;
    procedure CMBiDiModeChanged(var Message: TMessage); message CM_BIDIMODECHANGED;
    procedure CMDenySubclassing(var Message: TMessage); message CM_DENYSUBCLASSING;
    procedure CMDrag(var Message: TCMDrag); message CM_DRAG;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMHintShowPause(var Message: TCMHintShowPause); message CM_HINTSHOWPAUSE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseWheel(var Message: TCMMouseWheel); message CM_MOUSEWHEEL;
    procedure CMSysColorChange(var Message: TMessage); message CM_SYSCOLORCHANGE;
    procedure TVMGetItem(var Message: TMessage); message TVM_GETITEM;
    procedure TVMGetItemRect(var Message: TMessage); message TVM_GETITEMRECT;
    procedure TVMGetNextItem(var Message: TMessage); message TVM_GETNEXTITEM;
    procedure WMCancelMode(var Message: TWMCancelMode); message WM_CANCELMODE;
    procedure WMChangeState(var Message: TMessage); message WM_CHANGESTATE;
    procedure WMChar(var Message: TWMChar); message WM_CHAR;
    procedure WMContextMenu(var Message: TWMContextMenu); message WM_CONTEXTMENU;
    procedure WMCopy(var Message: TWMCopy); message WM_COPY;
    procedure WMCut(var Message: TWMCut); message WM_CUT;
    procedure WMEnable(var Message: TWMEnable); message WM_ENABLE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMGetObject(var Message: TMessage); message WM_GETOBJECT;
    procedure WMHScroll(var Message: TWMHScroll); message WM_HSCROLL;
    procedure WMKeyDown(var Message: TWMKeyDown); message WM_KEYDOWN;
    procedure WMKeyUp(var Message: TWMKeyUp); message WM_KEYUP;
    procedure WMKillFocus(var Msg: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure WMLButtonDown(var Message: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMMButtonDblClk(var Message: TWMMButtonDblClk); message WM_MBUTTONDBLCLK;
    procedure WMMButtonDown(var Message: TWMMButtonDown); message WM_MBUTTONDOWN;
    procedure WMMButtonUp(var Message: TWMMButtonUp); message WM_MBUTTONUP;
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCDestroy(var Message: TWMNCDestroy); message WM_NCDESTROY;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMNCPaint(var Message: TRealWMNCPaint); message WM_NCPAINT;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMPaste(var Message: TWMPaste); message WM_PASTE;
    procedure WMPrint(var Message: TWMPrint); message WM_PRINT;
    procedure WMPrintClient(var Message: TWMPrintClient); message WM_PRINTCLIENT;
    procedure WMRButtonDblClk(var Message: TWMRButtonDblClk); message WM_RBUTTONDBLCLK;
    procedure WMRButtonDown(var Message: TWMRButtonDown); message WM_RBUTTONDOWN;
    procedure WMRButtonUp(var Message: TWMRButtonUp); message WM_RBUTTONUP;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMSetFocus(var Msg: TWMSetFocus); message WM_SETFOCUS;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;
    procedure WMThemeChanged(var Message: TMessage); message WM_THEMECHANGED;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
    function GetRangeX: Cardinal;
    function GetDoubleBuffered: Boolean;
    procedure SetDoubleBuffered(const Value: Boolean);
  protected
    procedure AddToSelection(Node: PVirtualNode); overload; virtual;
    procedure AddToSelection(const NewItems: TNodeArray; NewLength: Integer; ForceInsert: Boolean = False); overload; virtual;
    procedure AdjustImageBorder(Images: TCustomImageList; BidiMode: TBidiMode; VAlign: Integer; var R: TRect;
      var ImageInfo: TVTImageInfo); virtual;
    procedure AdjustPaintCellRect(var PaintInfo: TVTPaintInfo; var NextNonEmpty: TColumnIndex); virtual;
    procedure AdjustPanningCursor(X, Y: Integer); virtual;
    procedure AdviseChangeEvent(StructureChange: Boolean; Node: PVirtualNode; Reason: TChangeReason); virtual;
    function AllocateInternalDataArea(Size: Cardinal): Cardinal; virtual;
    procedure Animate(Steps, Duration: Cardinal; Callback: TVTAnimationCallback; Data: Pointer); virtual;
    function CalculateSelectionRect(X, Y: Integer): Boolean; virtual;
    function CanAutoScroll: Boolean; virtual;
    function CanShowDragImage: Boolean; virtual;
    function CanSplitterResizeNode(P: TPoint; Node: PVirtualNode; Column: TColumnIndex): Boolean;
    procedure Change(Node: PVirtualNode); virtual;
    procedure ChangeScale(M, D: Integer); override;
    function CheckParentCheckState(Node: PVirtualNode; NewCheckState: TCheckState): Boolean; virtual;
    procedure ClearTempCache; virtual;
    function ColumnIsEmpty(Node: PVirtualNode; Column: TColumnIndex): Boolean; virtual;
    function ComputeRTLOffset(ExcludeScrollbar: Boolean = False): Integer; virtual;
    function CountLevelDifference(Node1, Node2: PVirtualNode): Integer; virtual;
    function CountVisibleChildren(Node: PVirtualNode): Cardinal; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DefineProperties(Filer: TFiler); override;
    function DetermineDropMode(const P: TPoint; var HitInfo: THitInfo; var NodeRect: TRect): TDropMode; virtual;
    procedure DetermineHiddenChildrenFlag(Node: PVirtualNode); virtual;
    procedure DetermineHiddenChildrenFlagAllNodes; virtual;
    procedure DetermineHitPositionLTR(var HitInfo: THitInfo; Offset, Right: Integer; Alignment: TAlignment); virtual;
    procedure DetermineHitPositionRTL(var HitInfo: THitInfo; Offset, Right: Integer; Alignment: TAlignment); virtual;
    function DetermineLineImageAndSelectLevel(Node: PVirtualNode; var LineImage: TLineImage): Integer; virtual;
    function DetermineNextCheckState(CheckType: TCheckType; CheckState: TCheckState): TCheckState; virtual;
    function DetermineScrollDirections(X, Y: Integer): TScrollDirections; virtual;
    procedure DoAdvancedHeaderDraw(var PaintInfo: THeaderPaintInfo; const Elements: THeaderPaintElements); virtual;
    procedure DoAfterCellPaint(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect); virtual;
    procedure DoAfterItemErase(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect); virtual;
    procedure DoAfterItemPaint(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect); virtual;
    procedure DoAfterPaint(Canvas: TCanvas); virtual;
    procedure DoAutoScroll(X, Y: Integer); virtual;
    function DoBeforeDrag(Node: PVirtualNode; Column: TColumnIndex): Boolean; virtual;
    procedure DoBeforeCellPaint(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect); virtual;
    procedure DoBeforeItemErase(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect; var Color: TColor;
      var EraseAction: TItemEraseAction); virtual;
    function DoBeforeItemPaint(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect): Boolean; virtual;
    procedure DoBeforePaint(Canvas: TCanvas); virtual;
    function DoCancelEdit: Boolean; virtual;
    procedure DoCanEdit(Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean); virtual;
    procedure DoCanSplitterResizeNode(P: TPoint; Node: PVirtualNode; Column: TColumnIndex;
      var Allowed: Boolean); virtual;
    procedure DoChange(Node: PVirtualNode); virtual;
    procedure DoCheckClick(Node: PVirtualNode; NewCheckState: TCheckState); virtual;
    procedure DoChecked(Node: PVirtualNode); virtual;
    function DoChecking(Node: PVirtualNode; var NewCheckState: TCheckState): Boolean; virtual;
    procedure DoCollapsed(Node: PVirtualNode); virtual;
    function DoCollapsing(Node: PVirtualNode): Boolean; virtual;
    procedure DoColumnClick(Column: TColumnIndex; Shift: TShiftState); virtual;
    procedure DoColumnDblClick(Column: TColumnIndex; Shift: TShiftState); virtual;
    procedure DoColumnResize(Column: TColumnIndex); virtual;
    function DoCompare(Node1, Node2: PVirtualNode; Column: TColumnIndex): Integer; virtual;
    function DoCreateDataObject: IDataObject; virtual;
    function DoCreateDragManager: IVTDragManager; virtual;
    function DoCreateEditor(Node: PVirtualNode; Column: TColumnIndex): IVTEditLink; virtual;
    procedure DoDragging(P: TPoint); virtual;
    procedure DoDragExpand; virtual;
    procedure DoBeforeDrawLineImage(Node: PVirtualNode; Level: Integer; var XPos: Integer); virtual;
    function DoDragOver(Source: TObject; Shift: TShiftState; State: TDragState; Pt: TPoint; Mode: TDropMode;
      var Effect: Integer): Boolean; virtual;
    procedure DoDragDrop(Source: TObject; DataObject: IDataObject; Formats: TFormatArray; Shift: TShiftState; Pt: TPoint;
      var Effect: Integer; Mode: TDropMode); virtual;
    procedure DoDrawHint(Canvas: TCanvas; Node: PVirtualNode; R: TRect; Column:
        TColumnIndex);
    procedure DoEdit; virtual;
    procedure DoEndDrag(Target: TObject; X, Y: Integer); override;
    function DoEndEdit: Boolean; virtual;
    procedure DoEndOperation(OperationKind: TVTOperationKind); virtual;
    procedure DoEnter(); override;
    procedure DoExpanded(Node: PVirtualNode); virtual;
    function DoExpanding(Node: PVirtualNode): Boolean; virtual;
    procedure DoFocusChange(Node: PVirtualNode; Column: TColumnIndex); virtual;
    function DoFocusChanging(OldNode, NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex): Boolean; virtual;
    procedure DoFocusNode(Node: PVirtualNode; Ask: Boolean); virtual;
    procedure DoFreeNode(Node: PVirtualNode); virtual;
    function DoGetAnimationType: THintAnimationType; virtual;
    function DoGetCellContentMargin(Node: PVirtualNode; Column: TColumnIndex;
      CellContentMarginType: TVTCellContentMarginType = ccmtAllSides; Canvas: TCanvas = nil): TPoint; virtual;
    procedure DoGetCursor(var Cursor: TCursor); virtual;
    procedure DoGetHeaderCursor(var Cursor: HCURSOR); virtual;
    procedure DoGetHintSize(Node: PVirtualNode; Column: TColumnIndex; var R:
        TRect); virtual;
    procedure DoGetHintKind(Node: PVirtualNode; Column: TColumnIndex; var Kind:
        TVTHintKind);
    function DoGetImageIndex(Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var Index: Integer): TCustomImageList; virtual;
    procedure DoGetImageText(Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var ImageText: UnicodeString); virtual;
    procedure DoGetLineStyle(var Bits: Pointer); virtual;
    function DoGetNodeHint(Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle): UnicodeString; virtual;
    function DoGetNodeTooltip(Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle): UnicodeString; virtual;
    function DoGetNodeExtraWidth(Node: PVirtualNode; Column: TColumnIndex; Canvas: TCanvas = nil): Integer; virtual;
    function DoGetNodeWidth(Node: PVirtualNode; Column: TColumnIndex; Canvas: TCanvas = nil): Integer; virtual;
    function DoGetPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint): TPopupMenu; virtual;
    procedure DoGetUserClipboardFormats(var Formats: TFormatEtcArray); virtual;
    procedure DoHeaderClick(HitInfo: TVTHeaderHitInfo); virtual;
    procedure DoHeaderDblClick(HitInfo: TVTHeaderHitInfo); virtual;
    procedure DoHeaderDragged(Column: TColumnIndex; OldPosition: TColumnPosition); virtual;
    procedure DoHeaderDraggedOut(Column: TColumnIndex; DropPosition: TPoint); virtual;
    function DoHeaderDragging(Column: TColumnIndex): Boolean; virtual;
    procedure DoHeaderDraw(Canvas: TCanvas; Column: TVirtualTreeColumn; R: TRect; Hover, Pressed: Boolean;
      DropMark: TVTDropMarkMode); virtual;
    procedure DoHeaderDrawQueryElements(var PaintInfo: THeaderPaintInfo; var Elements: THeaderPaintElements); virtual;
    procedure DoHeaderMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    procedure DoHeaderMouseMove(Shift: TShiftState; X, Y: Integer); virtual;
    procedure DoHeaderMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    procedure DoHotChange(Old, New: PVirtualNode); virtual;
    function DoIncrementalSearch(Node: PVirtualNode; const Text: UnicodeString): Integer; virtual;
    procedure DoInitChildren(Node: PVirtualNode; var ChildCount: Cardinal); virtual;
    procedure DoInitNode(Parent, Node: PVirtualNode; var InitStates: TVirtualNodeInitStates); virtual;
    function DoKeyAction(var CharCode: Word; var Shift: TShiftState): Boolean; virtual;
    procedure DoLoadUserData(Node: PVirtualNode; Stream: TStream); virtual;
    procedure DoMeasureItem(TargetCanvas: TCanvas; Node: PVirtualNode; var NodeHeight: Integer); virtual;
    procedure DoMouseEnter(); virtual;
    procedure DoMouseLeave(); virtual;
    procedure DoNodeCopied(Node: PVirtualNode); virtual;
    function DoNodeCopying(Node, NewParent: PVirtualNode): Boolean; virtual;
    procedure DoNodeClick(const HitInfo: THitInfo); virtual;
    procedure DoNodeDblClick(const HitInfo: THitInfo); virtual;
    function DoNodeHeightDblClickResize(Node: PVirtualNode; Column: TColumnIndex; Shift: TShiftState;
      P: TPoint): Boolean; virtual;
    function DoNodeHeightTracking(Node: PVirtualNode; Column: TColumnIndex;  Shift: TShiftState;
      var TrackPoint: TPoint; P: TPoint): Boolean; virtual;
    procedure DoNodeMoved(Node: PVirtualNode); virtual;
    function DoNodeMoving(Node, NewParent: PVirtualNode): Boolean; virtual;
    function DoPaintBackground(Canvas: TCanvas; R: TRect): Boolean; virtual;
    procedure DoPaintDropMark(Canvas: TCanvas; Node: PVirtualNode; R: TRect); virtual;
    procedure DoPaintNode(var PaintInfo: TVTPaintInfo); virtual;
    procedure DoPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint); virtual;
    procedure DoRemoveFromSelection(Node: PVirtualNode); virtual;
    function DoRenderOLEData(const FormatEtcIn: TFormatEtc; out Medium: TStgMedium;
      ForClipboard: Boolean): HRESULT; virtual;
    procedure DoReset(Node: PVirtualNode); virtual;
    procedure DoSaveUserData(Node: PVirtualNode; Stream: TStream); virtual;
    procedure DoScroll(DeltaX, DeltaY: Integer); virtual;
    function DoSetOffsetXY(Value: TPoint; Options: TScrollUpdateOptions; ClipRect: PRect = nil): Boolean; virtual;
    procedure DoShowScrollbar(Bar: Integer; Show: Boolean); virtual;
    procedure DoStartDrag(var DragObject: TDragObject); override;
    procedure DoStartOperation(OperationKind: TVTOperationKind); virtual;
    procedure DoStateChange(Enter: TVirtualTreeStates; Leave: TVirtualTreeStates = []); virtual;
    procedure DoStructureChange(Node: PVirtualNode; Reason: TChangeReason); virtual;
    procedure DoTimerScroll; virtual;
    procedure DoUpdating(State: TVTUpdateState); virtual;
    function DoValidateCache: Boolean; virtual;
    procedure DragAndDrop(AllowedEffects: DWord; DataObject: IDataObject;
      var DragEffect: LongInt); virtual;
    procedure DragCanceled; override;
    function DragDrop(const DataObject: IDataObject; KeyState: Integer; Pt: TPoint;
      var Effect: Integer): HResult; reintroduce; virtual;
    function DragEnter(KeyState: Integer; Pt: TPoint; var Effect: Integer): HResult; virtual;
    procedure DragFinished; virtual;
    procedure DragLeave; virtual;
    function DragOver(Source: TObject; KeyState: Integer; DragState: TDragState; Pt: TPoint;
      var Effect: LongInt): HResult; reintroduce; virtual;
    procedure DrawDottedHLine(const PaintInfo: TVTPaintInfo; Left, Right, Top: Integer); virtual;
    procedure DrawDottedVLine(const PaintInfo: TVTPaintInfo; Top, Bottom, Left: Integer); virtual;
    procedure EndOperation(OperationKind: TVTOperationKind);
    procedure EnsureNodeFocused(); virtual;
    function FindNodeInSelection(P: PVirtualNode; var Index: Integer; LowBound, HighBound: Integer): Boolean; virtual;
    procedure FinishChunkHeader(Stream: TStream; StartPos, EndPos: Integer); virtual;
    procedure FontChanged(AFont: TObject); virtual;
    function GetBorderDimensions: TSize; virtual;
    function GetCheckImage(Node: PVirtualNode; ImgCheckType: TCheckType = ctNone;
      ImgCheckState: TCheckState = csUncheckedNormal; ImgEnabled: Boolean = True): Integer; virtual;
    class function GetCheckImageListFor(Kind: TCheckImageKind): TCustomImageList; virtual;
    function GetColumnClass: TVirtualTreeColumnClass; virtual;
    function GetDefaultHintKind: TVTHintKind; virtual;
    function GetHeaderClass: TVTHeaderClass; virtual;
    function GetHintWindowClass: THintWindowClass; virtual;
    procedure GetImageIndex(var Info: TVTPaintInfo; Kind: TVTImageKind; InfoIndex: TVTImageInfoIndex;
      DefaultImages: TCustomImageList); virtual;
    function GetNodeImageSize(Node: PVirtualNode): TSize; virtual;
    function GetMaxRightExtend: Cardinal; virtual;
    procedure GetNativeClipboardFormats(var Formats: TFormatEtcArray); virtual;
    function GetOperationCanceled: Boolean;
    function GetOptionsClass: TTreeOptionsClass; virtual;
    function GetTreeFromDataObject(const DataObject: IDataObject): TBaseVirtualTree; virtual;
    procedure HandleHotTrack(X, Y: Integer); virtual;
    procedure HandleIncrementalSearch(CharCode: Word); virtual;
    procedure HandleMouseDblClick(var Message: TWMMouse; const HitInfo: THitInfo); virtual;
    procedure HandleMouseDown(var Message: TWMMouse; var HitInfo: THitInfo); virtual;
    procedure HandleMouseUp(var Message: TWMMouse; const HitInfo: THitInfo); virtual;
    function HasImage(Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex): Boolean; virtual;
    function HasPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Pos: TPoint): Boolean; virtual;
    procedure InitChildren(Node: PVirtualNode); virtual;
    procedure InitNode(Node: PVirtualNode); virtual;
    procedure InternalAddFromStream(Stream: TStream; Version: Integer; Node: PVirtualNode); virtual;
    function InternalAddToSelection(Node: PVirtualNode; ForceInsert: Boolean): Boolean; overload;
    function InternalAddToSelection(const NewItems: TNodeArray; NewLength: Integer;
      ForceInsert: Boolean): Boolean; overload;
    procedure InternalCacheNode(Node: PVirtualNode); virtual;
    procedure InternalClearSelection; virtual;
    procedure InternalConnectNode(Node, Destination: PVirtualNode; Target: TBaseVirtualTree; Mode: TVTNodeAttachMode); virtual;
    function InternalData(Node: PVirtualNode): Pointer;
    procedure InternalDisconnectNode(Node: PVirtualNode; KeepFocus: Boolean; Reindex: Boolean = True); virtual;
    procedure InternalRemoveFromSelection(Node: PVirtualNode); virtual;
    procedure InvalidateCache;
    procedure Loaded; override;
    procedure MainColumnChanged; virtual;
    procedure MarkCutCopyNodes; virtual;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure OriginalWMNCPaint(DC: HDC); virtual;
    procedure Paint; override;
    procedure PaintCheckImage(Canvas: TCanvas; const ImageInfo: TVTImageInfo; Selected: Boolean); virtual;
    procedure PaintImage(var PaintInfo: TVTPaintInfo; ImageInfoIndex: TVTImageInfoIndex; DoOverlay: Boolean); virtual;
    procedure PaintNodeButton(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; const R: TRect; ButtonX,
      ButtonY: Integer; BidiMode: TBiDiMode); virtual;
    procedure PaintTreeLines(const PaintInfo: TVTPaintInfo; VAlignment, IndentSize: Integer;
      LineImage: TLineImage); virtual;
    procedure PaintSelectionRectangle(Target: TCanvas; WindowOrgX: Integer; const SelectionRect: TRect;
      TargetRect: TRect); virtual;
    procedure PanningWindowProc(var Message: TMessage); virtual;
    procedure PrepareCell(var PaintInfo: TVTPaintInfo; WindowOrgX, MaxWidth: Integer); virtual;
    function ReadChunk(Stream: TStream; Version: Integer; Node: PVirtualNode; ChunkType,
      ChunkSize: Integer): Boolean; virtual;
    procedure ReadNode(Stream: TStream; Version: Integer; Node: PVirtualNode); virtual;
    procedure RedirectFontChangeEvent(Canvas: TCanvas); virtual;
    procedure RemoveFromSelection(Node: PVirtualNode); virtual;
    function RenderOLEData(const FormatEtcIn: TFormatEtc; out Medium: TStgMedium; ForClipboard: Boolean): HResult; virtual;
    procedure ResetRangeAnchor; virtual;
    procedure RestoreFontChangeEvent(Canvas: TCanvas); virtual;
    procedure SelectNodes(StartNode, EndNode: PVirtualNode; AddOnly: Boolean); virtual;
    procedure SetFocusedNodeAndColumn(Node: PVirtualNode; Column: TColumnIndex); virtual;
    procedure SkipNode(Stream: TStream); virtual;
    procedure StartOperation(OperationKind: TVTOperationKind);
    procedure StartWheelPanning(Position: TPoint); virtual;
    procedure StopWheelPanning; virtual;
    procedure StructureChange(Node: PVirtualNode; Reason: TChangeReason); virtual;
    function SuggestDropEffect(Source: TObject; Shift: TShiftState; Pt: TPoint; AllowedEffects: Integer): Integer; virtual;
    procedure ToggleSelection(StartNode, EndNode: PVirtualNode); virtual;
    procedure UnselectNodes(StartNode, EndNode: PVirtualNode); virtual;
    procedure UpdateColumnCheckState(Col: TVirtualTreeColumn);
    procedure UpdateDesigner; virtual;
    procedure UpdateEditBounds; virtual;
    procedure UpdateHeaderRect; virtual;
    procedure UpdateWindowAndDragImage(const Tree: TBaseVirtualTree; TreeRect: TRect; UpdateNCArea,
      ReshowDragImage: Boolean); virtual;
    procedure ValidateCache; virtual;
    procedure ValidateNodeDataSize(var Size: Integer); virtual;
    procedure WndProc(var Message: TMessage); override;
    procedure WriteChunks(Stream: TStream; Node: PVirtualNode); virtual;
    procedure WriteNode(Stream: TStream; Node: PVirtualNode); virtual;

    procedure VclStyleChanged;
    property VclStyleEnabled: Boolean read FVclStyleEnabled;

    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property AnimationDuration: Cardinal read FAnimationDuration write SetAnimationDuration default 200;
    property AutoExpandDelay: Cardinal read FAutoExpandDelay write FAutoExpandDelay default 1000;
    property AutoScrollDelay: Cardinal read FAutoScrollDelay write FAutoScrollDelay default 1000;
    property AutoScrollInterval: TAutoScrollInterval read FAutoScrollInterval write FAutoScrollInterval default 1;
    property Background: TPicture read FBackground write SetBackground;
    property BackgroundOffsetX: Integer index 0 read FBackgroundOffsetX write SetBackgroundOffset default 0;
    property BackgroundOffsetY: Integer index 1 read FBackgroundOffsetY write SetBackgroundOffset default 0;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property BottomSpace: Cardinal read FBottomSpace write SetBottomSpace default 0;
    property ButtonFillMode: TVTButtonFillMode read FButtonFillMode write SetButtonFillMode default fmTreeColor;
    property ButtonStyle: TVTButtonStyle read FButtonStyle write SetButtonStyle default bsRectangle;
    property ChangeDelay: Cardinal read FChangeDelay write FChangeDelay default 0;
    property CheckImageKind: TCheckImageKind read FCheckImageKind write SetCheckImageKind default ckSystemDefault;
    property ClipboardFormats: TClipboardFormats read FClipboardFormats write SetClipboardFormats;
    property Colors: TVTColors read FColors write SetColors;
    property CustomCheckImages: TCustomImageList read FCustomCheckImages write SetCustomCheckImages;
    property DefaultHintKind: TVTHintKind read GetDefaultHintKind;
    property DefaultNodeHeight: Cardinal read FDefaultNodeHeight write SetDefaultNodeHeight default 18;
    property DefaultPasteMode: TVTNodeAttachMode read FDefaultPasteMode write FDefaultPasteMode default amAddChildLast;
    property DragHeight: Integer read FDragHeight write FDragHeight default 350;
    property DragImageKind: TVTDragImageKind read FDragImageKind write FDragImageKind default diComplete;
    property DragOperations: TDragOperations read FDragOperations write FDragOperations default [doCopy, doMove];
    property DragSelection: TNodeArray read FDragSelection;
    property LastDragEffect: LongInt read FLastDragEffect;
    property DragType: TVTDragType read FDragType write FDragType default dtOLE;
    property DragWidth: Integer read FDragWidth write FDragWidth default 200;
    property DrawSelectionMode: TVTDrawSelectionMode read FDrawSelectionMode write FDrawSelectionMode
      default smDottedRectangle;
    property EditColumn: TColumnIndex read FEditColumn write FEditColumn;
    property EditDelay: Cardinal read FEditDelay write FEditDelay default 1000;
    property EffectiveOffsetX: Integer read FEffectiveOffsetX;
    property Header: TVTHeader read FHeader write SetHeader;
    property HeaderRect: TRect read FHeaderRect;
    property HintAnimation: THintAnimationType read FAnimationType write FAnimationType default hatSystemDefault;
    property HintMode: TVTHintMode read FHintMode write FHintMode default hmDefault;
    property HintData: TVTHintData read FHintData write FHintData;
    property HotCursor: TCursor read FHotCursor write FHotCursor default crDefault;
    property Images: TCustomImageList read FImages write SetImages;
    property IncrementalSearch: TVTIncrementalSearch read FIncrementalSearch write SetSearchOption default isNone;
    property IncrementalSearchDirection: TVTSearchDirection read FSearchDirection write FSearchDirection default sdForward;
    property IncrementalSearchStart: TVTSearchStart read FSearchStart write FSearchStart default ssFocusedNode;
    property IncrementalSearchTimeout: Cardinal read FSearchTimeout write FSearchTimeout default 1000;
    property Indent: Cardinal read FIndent write SetIndent default 18;
    property LastClickPos: TPoint read FLastClickPos write FLastClickPos;
    property LastDropMode: TDropMode read FLastDropMode write FlastDropMode;
    property LastHintRect: TRect read FLastHintRect write FLastHintRect;
    property LineMode: TVTLineMode read FLineMode write SetLineMode default lmNormal;
    property LineStyle: TVTLineStyle read FLineStyle write SetLineStyle default lsDotted;
    property Margin: Integer read FMargin write SetMargin default 4;
    property NodeAlignment: TVTNodeAlignment read FNodeAlignment write SetNodeAlignment default naProportional;
    property NodeDataSize: Integer read FNodeDataSize write SetNodeDataSize default -1;
    property OperationCanceled: Boolean read GetOperationCanceled;
    property HotMinusBM: TBitmap read FHotMinusBM;
    property HotPlusBM: TBitmap read FHotPlusBM;
    property MinusBM: TBitmap read FMinusBM;
    property PlusBM: TBitmap read FPlusBM;
    property RangeX: Cardinal read GetRangeX;
    property RangeY: Cardinal read FRangeY;
    property RootNodeCount: Cardinal read GetRootNodeCount write SetRootNodeCount default 0;
    property ScrollBarOptions: TScrollBarOptions read FScrollBarOptions write SetScrollBarOptions;
    property SelectionBlendFactor: Byte read FSelectionBlendFactor write FSelectionBlendFactor default 128;
    property SelectionCurveRadius: Cardinal read FSelectionCurveRadius write SetSelectionCurveRadius default 0;
    property StateImages: TCustomImageList read FStateImages write SetStateImages;
    property TextMargin: Integer read FTextMargin write SetTextMargin default 4;
    property TotalInternalDataSize: Cardinal read FTotalInternalDataSize;
    property TreeOptions: TCustomVirtualTreeOptions read FOptions write SetOptions;
    property WantTabs: Boolean read FWantTabs write FWantTabs default False;

    property OnAddToSelection: TVTAddToSelectionEvent read FOnAddToSelection write FOnAddToSelection;
    property OnAdvancedHeaderDraw: TVTAdvancedHeaderPaintEvent read FOnAdvancedHeaderDraw write FOnAdvancedHeaderDraw;
    property OnAfterAutoFitColumn: TVTAfterAutoFitColumnEvent read FOnAfterAutoFitColumn write FOnAfterAutoFitColumn;
    property OnAfterAutoFitColumns: TVTAfterAutoFitColumnsEvent read FOnAfterAutoFitColumns write FOnAfterAutoFitColumns;
    property OnAfterCellPaint: TVTAfterCellPaintEvent read FOnAfterCellPaint write FOnAfterCellPaint;
    property OnAfterColumnExport : TVTColumnExportEvent read FOnAfterColumnExport write FOnAfterColumnExport;
    property OnAfterColumnWidthTracking: TVTAfterColumnWidthTrackingEvent read FOnAfterColumnWidthTracking write FOnAfterColumnWidthTracking;
    property OnAfterGetMaxColumnWidth: TVTAfterGetMaxColumnWidthEvent read FOnAfterGetMaxColumnWidth write FOnAfterGetMaxColumnWidth;
    property OnAfterHeaderExport: TVTTreeExportEvent read FOnAfterHeaderExport write FOnAfterHeaderExport;
    property OnAfterHeaderHeightTracking: TVTAfterHeaderHeightTrackingEvent read FOnAfterHeaderHeightTracking
      write FOnAfterHeaderHeightTracking;
    property OnAfterItemErase: TVTAfterItemEraseEvent read FOnAfterItemErase write FOnAfterItemErase;
    property OnAfterItemPaint: TVTAfterItemPaintEvent read FOnAfterItemPaint write FOnAfterItemPaint;
    property OnAfterNodeExport: TVTNodeExportEvent read FOnAfterNodeExport write FOnAfterNodeExport;
    property OnAfterPaint: TVTPaintEvent read FOnAfterPaint write FOnAfterPaint;
    property OnAfterTreeExport: TVTTreeExportEvent read FOnAfterTreeExport write FOnAfterTreeExport;
    property OnBeforeAutoFitColumn: TVTBeforeAutoFitColumnEvent read FOnBeforeAutoFitColumn write FOnBeforeAutoFitColumn;
    property OnBeforeAutoFitColumns: TVTBeforeAutoFitColumnsEvent read FOnBeforeAutoFitColumns write FOnBeforeAutoFitColumns;
    property OnBeforeCellPaint: TVTBeforeCellPaintEvent read FOnBeforeCellPaint write FOnBeforeCellPaint;
    property OnBeforeColumnExport: TVTColumnExportEvent read FOnBeforeColumnExport write FOnBeforeColumnExport;
    property OnBeforeColumnWidthTracking: TVTBeforeColumnWidthTrackingEvent read FOnBeforeColumnWidthTracking
      write FOnBeforeColumnWidthTracking;
    property OnBeforeDrawTreeLine: TVTBeforeDrawLineImageEvent read FOnBeforeDrawLineImage write FOnBeforeDrawLineImage;
    property OnBeforeGetMaxColumnWidth: TVTBeforeGetMaxColumnWidthEvent read FOnBeforeGetMaxColumnWidth write FOnBeforeGetMaxColumnWidth;
    property OnBeforeHeaderExport: TVTTreeExportEvent read FOnBeforeHeaderExport write FOnBeforeHeaderExport;
    property OnBeforeHeaderHeightTracking: TVTBeforeHeaderHeightTrackingEvent read FOnBeforeHeaderHeightTracking
      write FOnBeforeHeaderHeightTracking;
    property OnBeforeItemErase: TVTBeforeItemEraseEvent read FOnBeforeItemErase write FOnBeforeItemErase;
    property OnBeforeItemPaint: TVTBeforeItemPaintEvent read FOnBeforeItemPaint write FOnBeforeItemPaint;
    property OnBeforeNodeExport: TVTNodeExportEvent read FOnBeforeNodeExport write FOnBeforeNodeExport;
    property OnBeforePaint: TVTPaintEvent read FOnBeforePaint write FOnBeforePaint;
    property OnBeforeTreeExport: TVTTreeExportEvent read FOnBeforeTreeExport write FOnBeforeTreeExport;
    property OnCanSplitterResizeColumn: TVTCanSplitterResizeColumnEvent read FOnCanSplitterResizeColumn write FOnCanSplitterResizeColumn;
    property OnCanSplitterResizeHeader: TVTCanSplitterResizeHeaderEvent read FOnCanSplitterResizeHeader write FOnCanSplitterResizeHeader;
    property OnCanSplitterResizeNode: TVTCanSplitterResizeNodeEvent read FOnCanSplitterResizeNode write FOnCanSplitterResizeNode;
    property OnChange: TVTChangeEvent read FOnChange write FOnChange;
    property OnChecked: TVTChangeEvent read FOnChecked write FOnChecked;
    property OnChecking: TVTCheckChangingEvent read FOnChecking write FOnChecking;
    property OnCollapsed: TVTChangeEvent read FOnCollapsed write FOnCollapsed;
    property OnCollapsing: TVTChangingEvent read FOnCollapsing write FOnCollapsing;
    property OnColumnClick: TVTColumnClickEvent read FOnColumnClick write FOnColumnClick;
    property OnColumnDblClick: TVTColumnDblClickEvent read FOnColumnDblClick write FOnColumnDblClick;
    property OnColumnExport : TVTColumnExportEvent read FOnColumnExport write FOnColumnExport;
    property OnColumnResize: TVTHeaderNotifyEvent read FOnColumnResize write FOnColumnResize;
    property OnColumnWidthDblClickResize: TVTColumnWidthDblClickResizeEvent read FOnColumnWidthDblClickResize
      write FOnColumnWidthDblClickResize;
    property OnColumnWidthTracking: TVTColumnWidthTrackingEvent read FOnColumnWidthTracking write FOnColumnWidthTracking;
    property OnCompareNodes: TVTCompareEvent read FOnCompareNodes write FOnCompareNodes;
    property OnCreateDataObject: TVTCreateDataObjectEvent read FOnCreateDataObject write FOnCreateDataObject;
    property OnCreateDragManager: TVTCreateDragManagerEvent read FOnCreateDragManager write FOnCreateDragManager;
    property OnCreateEditor: TVTCreateEditorEvent read FOnCreateEditor write FOnCreateEditor;
    property OnDragAllowed: TVTDragAllowedEvent read FOnDragAllowed write FOnDragAllowed;
    property OnDragOver: TVTDragOverEvent read FOnDragOver write FOnDragOver;
    property OnDragDrop: TVTDragDropEvent read FOnDragDrop write FOnDragDrop;
    property OnDrawHint: TVTDrawHintEvent read FOnDrawHint write FOnDrawHint;
    property OnEditCancelled: TVTEditCancelEvent read FOnEditCancelled write FOnEditCancelled;
    property OnEditing: TVTEditChangingEvent read FOnEditing write FOnEditing;
    property OnEdited: TVTEditChangeEvent read FOnEdited write FOnEdited;
    property OnEndOperation: TVTOperationEvent read FOnEndOperation write FOnEndOperation;
    property OnExpanded: TVTChangeEvent read FOnExpanded write FOnExpanded;
    property OnExpanding: TVTChangingEvent read FOnExpanding write FOnExpanding;
    property OnFocusChanged: TVTFocusChangeEvent read FOnFocusChanged write FOnFocusChanged;
    property OnFocusChanging: TVTFocusChangingEvent read FOnFocusChanging write FOnFocusChanging;
    property OnFreeNode: TVTFreeNodeEvent read FOnFreeNode write FOnFreeNode;
    property OnGetCellIsEmpty: TVTGetCellIsEmptyEvent read FOnGetCellIsEmpty write FOnGetCellIsEmpty;
    property OnGetCursor: TVTGetCursorEvent read FOnGetCursor write FOnGetCursor;
    property OnGetHeaderCursor: TVTGetHeaderCursorEvent read FOnGetHeaderCursor write FOnGetHeaderCursor;
    property OnGetHelpContext: TVTHelpContextEvent read FOnGetHelpContext write FOnGetHelpContext;
    property OnGetHintSize: TVTGetHintSizeEvent read FOnGetHintSize write
        FOnGetHintSize;
    property OnGetHintKind: TVTHintKindEvent read fOnGetHintKind write
        fOnGetHintKind;
    property OnGetImageIndex: TVTGetImageEvent read FOnGetImage write FOnGetImage;
    property OnGetImageIndexEx: TVTGetImageExEvent read FOnGetImageEx write FOnGetImageEx;
    property OnGetImageText: TVTGetImageTextEvent read FOnGetImageText write FOnGetImageText;
    property OnGetLineStyle: TVTGetLineStyleEvent read FOnGetLineStyle write FOnGetLineStyle;
    property OnGetNodeDataSize: TVTGetNodeDataSizeEvent read FOnGetNodeDataSize write FOnGetNodeDataSize;
    property OnGetPopupMenu: TVTPopupEvent read FOnGetPopupMenu write FOnGetPopupMenu;
    property OnGetUserClipboardFormats: TVTGetUserClipboardFormatsEvent read FOnGetUserClipboardFormats
      write FOnGetUserClipboardFormats;
    property OnHeaderClick: TVTHeaderClickEvent read FOnHeaderClick write FOnHeaderClick;
    property OnHeaderDblClick: TVTHeaderClickEvent read FOnHeaderDblClick write FOnHeaderDblClick;
    property OnHeaderDragged: TVTHeaderDraggedEvent read FOnHeaderDragged write FOnHeaderDragged;
    property OnHeaderDraggedOut: TVTHeaderDraggedOutEvent read FOnHeaderDraggedOut write FOnHeaderDraggedOut;
    property OnHeaderDragging: TVTHeaderDraggingEvent read FOnHeaderDragging write FOnHeaderDragging;
    property OnHeaderDraw: TVTHeaderPaintEvent read FOnHeaderDraw write FOnHeaderDraw;
    property OnHeaderDrawQueryElements: TVTHeaderPaintQueryElementsEvent read FOnHeaderDrawQueryElements
      write FOnHeaderDrawQueryElements;
    property OnHeaderHeightTracking: TVTHeaderHeightTrackingEvent read FOnHeaderHeightTracking
      write FOnHeaderHeightTracking;
    property OnHeaderHeightDblClickResize: TVTHeaderHeightDblClickResizeEvent read FOnHeaderHeightDblClickResize
      write FOnHeaderHeightDblClickResize;
    property OnHeaderMouseDown: TVTHeaderMouseEvent read FOnHeaderMouseDown write FOnHeaderMouseDown;
    property OnHeaderMouseMove: TVTHeaderMouseMoveEvent read FOnHeaderMouseMove write FOnHeaderMouseMove;
    property OnHeaderMouseUp: TVTHeaderMouseEvent read FOnHeaderMouseUp write FOnHeaderMouseUp;
    property OnHotChange: TVTHotNodeChangeEvent read FOnHotChange write FOnHotChange;
    property OnIncrementalSearch: TVTIncrementalSearchEvent read FOnIncrementalSearch write FOnIncrementalSearch;
    property OnInitChildren: TVTInitChildrenEvent read FOnInitChildren write FOnInitChildren;
    property OnInitNode: TVTInitNodeEvent read FOnInitNode write FOnInitNode;
    property OnKeyAction: TVTKeyActionEvent read FOnKeyAction write FOnKeyAction;
    property OnLoadNode: TVTSaveNodeEvent read FOnLoadNode write FOnLoadNode;
    property OnLoadTree: TVTSaveTreeEvent read FOnLoadTree write FOnLoadTree;
    property OnMeasureItem: TVTMeasureItemEvent read FOnMeasureItem write FOnMeasureItem;
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
    property OnNodeClick: TVTNodeClickEvent read FOnNodeClick write FOnNodeClick;
    property OnNodeCopied: TVTNodeCopiedEvent read FOnNodeCopied write FOnNodeCopied;
    property OnNodeCopying: TVTNodeCopyingEvent read FOnNodeCopying write FOnNodeCopying;
    property OnNodeDblClick: TVTNodeClickEvent read FOnNodeDblClick write FOnNodeDblClick;
    property OnNodeExport: TVTNodeExportEvent read FOnNodeExport write FOnNodeExport;
    property OnNodeHeightTracking: TVTNodeHeightTrackingEvent read FOnNodeHeightTracking write FOnNodeHeightTracking;
    property OnNodeHeightDblClickResize: TVTNodeHeightDblClickResizeEvent read FOnNodeHeightDblClickResize
      write FOnNodeHeightDblClickResize;
    property OnNodeMoved: TVTNodeMovedEvent read FOnNodeMoved write FOnNodeMoved;
    property OnNodeMoving: TVTNodeMovingEvent read FOnNodeMoving write FOnNodeMoving;
    property OnPaintBackground: TVTBackgroundPaintEvent read FOnPaintBackground write FOnPaintBackground;
    property OnRemoveFromSelection: TVTRemoveFromSelectionEvent read FOnRemoveFromSelection write FOnRemoveFromSelection;
    property OnRenderOLEData: TVTRenderOLEDataEvent read FOnRenderOLEData write FOnRenderOLEData;
    property OnResetNode: TVTChangeEvent read FOnResetNode write FOnResetNode;
    property OnSaveNode: TVTSaveNodeEvent read FOnSaveNode write FOnSaveNode;
    property OnSaveTree: TVTSaveTreeEvent read FOnSaveTree write FOnSaveTree;
    property OnScroll: TVTScrollEvent read FOnScroll write FOnScroll;
    property OnShowScrollbar: TVTScrollbarShowEvent read FOnShowScrollbar write FOnShowScrollbar;
    property OnStartOperation: TVTOperationEvent read FOnStartOperation write FOnStartOperation;
    property OnStateChange: TVTStateChangeEvent read FOnStateChange write FOnStateChange;
    property OnStructureChange: TVTStructureChangeEvent read FOnStructureChange write FOnStructureChange;
    property OnUpdating: TVTUpdatingEvent read FOnUpdating write FOnUpdating;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function AbsoluteIndex(Node: PVirtualNode): Cardinal;
    function AddChild(Parent: PVirtualNode; UserData: Pointer = nil): PVirtualNode; virtual;
    procedure AddFromStream(Stream: TStream; TargetNode: PVirtualNode);
    procedure AfterConstruction; override;
    procedure Assign(Source: TPersistent); override;
    procedure BeginDrag(Immediate: Boolean; Threshold: Integer = -1);
    procedure BeginSynch;
    procedure BeginUpdate; virtual;
    procedure CancelCutOrCopy;
    function CancelEditNode: Boolean;
    procedure CancelOperation;
    function CanEdit(Node: PVirtualNode; Column: TColumnIndex): Boolean; virtual;
    function CanFocus: Boolean; override;
    procedure Clear; virtual;
    procedure ClearChecked;
    procedure ClearSelection;
    function CopyTo(Source: PVirtualNode; Tree: TBaseVirtualTree; Mode: TVTNodeAttachMode;
      ChildrenOnly: Boolean): PVirtualNode; overload;
    function CopyTo(Source, Target: PVirtualNode; Mode: TVTNodeAttachMode;
      ChildrenOnly: Boolean): PVirtualNode; overload;
    procedure CopyToClipBoard; virtual;
    procedure CutToClipBoard; virtual;
    procedure DeleteChildren(Node: PVirtualNode; ResetHasChildren: Boolean = False);
    procedure DeleteNode(Node: PVirtualNode; Reindex: Boolean = True);
    procedure DeleteSelectedNodes; virtual;
    function Dragging: Boolean;
    function EditNode(Node: PVirtualNode; Column: TColumnIndex): Boolean; virtual;
    function EndEditNode: Boolean;
    procedure EndSynch;
    procedure EndUpdate; virtual;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    procedure FinishCutOrCopy;
    procedure FlushClipboard;
    procedure FullCollapse(Node: PVirtualNode = nil);  virtual;
    procedure FullExpand(Node: PVirtualNode = nil); virtual;
    function GetControlsAlignment: TAlignment; override;
    function GetDisplayRect(Node: PVirtualNode; Column: TColumnIndex; TextOnly: Boolean; Unclipped: Boolean = False;
      ApplyCellContentMargin: Boolean = False): TRect;
    function GetEffectivelyFiltered(Node: PVirtualNode): Boolean;
    function GetEffectivelyVisible(Node: PVirtualNode): Boolean;
    function GetFirst(ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetFirstChecked(State: TCheckState = csCheckedNormal; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetFirstChild(Node: PVirtualNode): PVirtualNode;
    function GetFirstCutCopy(ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetFirstInitialized(ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetFirstLeaf: PVirtualNode;
    function GetFirstLevel(NodeLevel: Cardinal): PVirtualNode;
    function GetFirstNoInit(ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetFirstSelected(ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetFirstVisible(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = True;
      IncludeFiltered: Boolean = False): PVirtualNode;
    function GetFirstVisibleChild(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;
    function GetFirstVisibleChildNoInit(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;
    function GetFirstVisibleNoInit(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = True;
      IncludeFiltered: Boolean = False): PVirtualNode;
    procedure GetHitTestInfoAt(X, Y: Integer; Relative: Boolean; var HitInfo: THitInfo); virtual;
    function GetLast(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetLastInitialized(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetLastNoInit(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetLastChild(Node: PVirtualNode): PVirtualNode;
    function GetLastChildNoInit(Node: PVirtualNode): PVirtualNode;
    function GetLastVisible(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = True;
      IncludeFiltered: Boolean = False): PVirtualNode;
    function GetLastVisibleChild(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;
    function GetLastVisibleChildNoInit(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;
    function GetLastVisibleNoInit(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = True;
      IncludeFiltered: Boolean = False): PVirtualNode;
    function GetMaxColumnWidth(Column: TColumnIndex; UseSmartColumnWidth: Boolean = False): Integer; virtual;
    function GetNext(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetNextChecked(Node: PVirtualNode; State: TCheckState = csCheckedNormal;
      ConsiderChildrenAbove: Boolean = False): PVirtualNode; overload;
    function GetNextChecked(Node: PVirtualNode; ConsiderChildrenAbove: Boolean): PVirtualNode; overload;
    function GetNextCutCopy(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetNextInitialized(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetNextLeaf(Node: PVirtualNode): PVirtualNode;
    function GetNextLevel(Node: PVirtualNode; NodeLevel: Cardinal): PVirtualNode;
    function GetNextNoInit(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetNextSelected(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetNextSibling(Node: PVirtualNode): PVirtualNode;
    function GetNextSiblingNoInit(Node: PVirtualNode): PVirtualNode;
    function GetNextVisible(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = True): PVirtualNode;
    function GetNextVisibleNoInit(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = True): PVirtualNode;
    function GetNextVisibleSibling(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;
    function GetNextVisibleSiblingNoInit(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;
    function GetNodeAt(const P: TPoint): PVirtualNode; overload; {$if CompilerVersion >= 18}inline;{$ifend}
    function GetNodeAt(X, Y: Integer): PVirtualNode; overload;
    function GetNodeAt(X, Y: Integer; Relative: Boolean; var NodeTop: Integer): PVirtualNode; overload;
    function GetNodeData(Node: PVirtualNode): Pointer;
    function GetNodeLevel(Node: PVirtualNode): Cardinal;
    function GetPrevious(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetPreviousChecked(Node: PVirtualNode; State: TCheckState = csCheckedNormal;
      ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetPreviousCutCopy(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetPreviousInitialized(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetPreviousLeaf(Node: PVirtualNode): PVirtualNode;
    function GetPreviousLevel(Node: PVirtualNode; NodeLevel: Cardinal): PVirtualNode;
    function GetPreviousNoInit(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetPreviousSelected(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;
    function GetPreviousSibling(Node: PVirtualNode): PVirtualNode;
    function GetPreviousSiblingNoInit(Node: PVirtualNode): PVirtualNode;
    function GetPreviousVisible(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = True): PVirtualNode;
    function GetPreviousVisibleNoInit(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = True): PVirtualNode;
    function GetPreviousVisibleSibling(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;
    function GetPreviousVisibleSiblingNoInit(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;
    function GetSortedCutCopySet(Resolve: Boolean): TNodeArray;
    function GetSortedSelection(Resolve: Boolean): TNodeArray;
    procedure GetTextInfo(Node: PVirtualNode; Column: TColumnIndex; const AFont: TFont; var R: TRect;
      var Text: UnicodeString); virtual;
    function GetTreeRect: TRect;
    function GetVisibleParent(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;
    function HasAsParent(Node, PotentialParent: PVirtualNode): Boolean;
    function InsertNode(Node: PVirtualNode; Mode: TVTNodeAttachMode; UserData: Pointer = nil): PVirtualNode;
    procedure InvalidateChildren(Node: PVirtualNode; Recursive: Boolean);
    procedure InvalidateColumn(Column: TColumnIndex);
    function InvalidateNode(Node: PVirtualNode): TRect; virtual;
    procedure InvalidateToBottom(Node: PVirtualNode);
    procedure InvertSelection(VisibleOnly: Boolean);
    function IsEditing: Boolean;
    function IsMouseSelecting: Boolean;
    function IterateSubtree(Node: PVirtualNode; Callback: TVTGetNodeProc; Data: Pointer; Filter: TVirtualNodeStates = [];
      DoInit: Boolean = False; ChildNodesOnly: Boolean = False): PVirtualNode;
    procedure LoadFromFile(const FileName: TFileName); virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure MeasureItemHeight(const Canvas: TCanvas; Node: PVirtualNode);
    procedure MoveTo(Source, Target: PVirtualNode; Mode: TVTNodeAttachMode; ChildrenOnly: Boolean); overload;
    procedure MoveTo(Node: PVirtualNode; Tree: TBaseVirtualTree; Mode: TVTNodeAttachMode;
      ChildrenOnly: Boolean); overload;
    procedure PaintTree(TargetCanvas: TCanvas; Window: TRect; Target: TPoint; PaintOptions: TVTInternalPaintOptions;
      PixelFormat: TPixelFormat = pfDevice); virtual;
    function PasteFromClipboard: Boolean; virtual;
    procedure PrepareDragImage(HotSpot: TPoint; const DataObject: IDataObject);
    procedure Print(Printer: TPrinter; PrintHeader: Boolean);
    function ProcessDrop(DataObject: IDataObject; TargetNode: PVirtualNode; var Effect: Integer; Mode:
      TVTNodeAttachMode): Boolean;
    function ProcessOLEData(Source: TBaseVirtualTree; DataObject: IDataObject; TargetNode: PVirtualNode;
      Mode: TVTNodeAttachMode; Optimized: Boolean): Boolean;
    procedure RepaintNode(Node: PVirtualNode);
    procedure ReinitChildren(Node: PVirtualNode; Recursive: Boolean); virtual;
    procedure ReinitNode(Node: PVirtualNode; Recursive: Boolean); virtual;
    procedure ResetNode(Node: PVirtualNode); virtual;
    procedure SaveToFile(const FileName: TFileName);
    procedure SaveToStream(Stream: TStream; Node: PVirtualNode = nil); virtual;
    function ScrollIntoView(Node: PVirtualNode; Center: Boolean; Horizontally: Boolean = False): Boolean; overload;
    function ScrollIntoView(Column: TColumnIndex; Center: Boolean): Boolean; overload;
    procedure SelectAll(VisibleOnly: Boolean);
    procedure Sort(Node: PVirtualNode; Column: TColumnIndex; Direction: TSortDirection; DoInit: Boolean = True); virtual;
    procedure SortTree(Column: TColumnIndex; Direction: TSortDirection; DoInit: Boolean = True); virtual;
    procedure ToggleNode(Node: PVirtualNode);
    function UpdateAction(Action: TBasicAction): Boolean; override;
    procedure UpdateHorizontalRange;
    procedure UpdateHorizontalScrollBar(DoRepaint: Boolean); virtual;
    procedure UpdateRanges;
    procedure UpdateScrollBars(DoRepaint: Boolean); virtual;
    procedure UpdateVerticalRange;
    procedure UpdateVerticalScrollBar(DoRepaint: Boolean); virtual;
    function UseRightToLeftReading: Boolean;
    procedure ValidateChildren(Node: PVirtualNode; Recursive: Boolean);
    procedure ValidateNode(Node: PVirtualNode; Recursive: Boolean);
    
    function Nodes(ConsiderChildrenAbove: Boolean = False): TVTVirtualNodeEnumeration;
    function CheckedNodes(State: TCheckState = csCheckedNormal; ConsiderChildrenAbove: Boolean = False): TVTVirtualNodeEnumeration;
    function ChildNodes(Node: PVirtualNode): TVTVirtualNodeEnumeration;
    function CutCopyNodes(ConsiderChildrenAbove: Boolean = False): TVTVirtualNodeEnumeration;
    function InitializedNodes(ConsiderChildrenAbove: Boolean = False): TVTVirtualNodeEnumeration;
    function LeafNodes: TVTVirtualNodeEnumeration;
    function LevelNodes(NodeLevel: Cardinal): TVTVirtualNodeEnumeration;
    function NoInitNodes(ConsiderChildrenAbove: Boolean = False): TVTVirtualNodeEnumeration;
    function SelectedNodes(ConsiderChildrenAbove: Boolean = False): TVTVirtualNodeEnumeration;
    function VisibleNodes(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = True;
      IncludeFiltered: Boolean = False): TVTVirtualNodeEnumeration;
    function VisibleChildNodes(Node: PVirtualNode; IncludeFiltered: Boolean = False): TVTVirtualNodeEnumeration;
    function VisibleChildNoInitNodes(Node: PVirtualNode; IncludeFiltered: Boolean = False): TVTVirtualNodeEnumeration;
    function VisibleNoInitNodes(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = True;
      IncludeFiltered: Boolean = False): TVTVirtualNodeEnumeration;

    property Accessible: IAccessible read FAccessible write FAccessible;
    property AccessibleItem: IAccessible read FAccessibleItem write FAccessibleItem;
    property AccessibleName: string read FAccessibleName write FAccessibleName;
    property BottomNode: PVirtualNode read GetBottomNode write SetBottomNode;
    property CheckedCount: Integer read GetCheckedCount;
    property CheckImages: TCustomImageList read FCheckImages;
    property CheckState[Node: PVirtualNode]: TCheckState read GetCheckState write SetCheckState;
    property CheckType[Node: PVirtualNode]: TCheckType read GetCheckType write SetCheckType;
    property ChildCount[Node: PVirtualNode]: Cardinal read GetChildCount write SetChildCount;
    property ChildrenInitialized[Node: PVirtualNode]: Boolean read GetChildrenInitialized;
    property CutCopyCount: Integer read GetCutCopyCount;
    property DragImage: TVTDragImage read FDragImage;
    property DragManager: IVTDragManager read GetDragManager;
    property DropTargetNode: PVirtualNode read FDropTargetNode write FDropTargetNode;
    property EditLink: IVTEditLink read FEditLink;
    property EmptyListMessage: UnicodeString read FEmptyListMessage write SetEmptyListMessage;
    property Expanded[Node: PVirtualNode]: Boolean read GetExpanded write SetExpanded;
    property FocusedColumn: TColumnIndex read FFocusedColumn write SetFocusedColumn default InvalidColumn;
    property FocusedNode: PVirtualNode read FFocusedNode write SetFocusedNode;
    property Font;
    property FullyVisible[Node: PVirtualNode]: Boolean read GetFullyVisible write SetFullyVisible;
    property HasChildren[Node: PVirtualNode]: Boolean read GetHasChildren write SetHasChildren;
    property HotNode: PVirtualNode read FCurrentHotNode;
    property IsDisabled[Node: PVirtualNode]: Boolean read GetDisabled write SetDisabled;
    property IsEffectivelyFiltered[Node: PVirtualNode]: Boolean read GetEffectivelyFiltered;
    property IsEffectivelyVisible[Node: PVirtualNode]: Boolean read GetEffectivelyVisible;
    property IsFiltered[Node: PVirtualNode]: Boolean read GetFiltered write SetFiltered;
    property IsVisible[Node: PVirtualNode]: Boolean read GetVisible write SetVisible;
    property MultiLine[Node: PVirtualNode]: Boolean read GetMultiline write SetMultiline;
    property NodeHeight[Node: PVirtualNode]: Cardinal read GetNodeHeight write SetNodeHeight;
    property NodeParent[Node: PVirtualNode]: PVirtualNode read GetNodeParent write SetNodeParent;
    property OffsetX: Integer read FOffsetX write SetOffsetX;
    property OffsetXY: TPoint read GetOffsetXY write SetOffsetXY;
    property OffsetY: Integer read FOffsetY write SetOffsetY;
    property OperationCount: Cardinal read FOperationCount;
    property RootNode: PVirtualNode read FRoot;
    property SearchBuffer: UnicodeString read FSearchBuffer;
    property Selected[Node: PVirtualNode]: Boolean read GetSelected write SetSelected;
    property SelectionLocked: Boolean read FSelectionLocked write FSelectionLocked;
    property TotalCount: Cardinal read GetTotalCount;
    property TreeStates: TVirtualTreeStates read FStates write FStates;
    property SelectedCount: Integer read FSelectionCount;
    property TopNode: PVirtualNode read GetTopNode write SetTopNode;
    property VerticalAlignment[Node: PVirtualNode]: Byte read GetVerticalAlignment write SetVerticalAlignment;
    property VisibleCount: Cardinal read FVisibleCount;
    property VisiblePath[Node: PVirtualNode]: Boolean read GetVisiblePath write SetVisiblePath;
    property UpdateCount: Cardinal read FUpdateCount;
    property DoubleBuffered: Boolean read GetDoubleBuffered write SetDoubleBuffered default True;
  end;
  
  TVTStringOption = (
    toSaveCaptions,          
                             
    toShowStaticText,        
                             
    toAutoAcceptEditChange   
                             
  );
  TVTStringOptions = set of TVTStringOption;

const
  DefaultStringOptions = [toSaveCaptions, toAutoAcceptEditChange];

type
  TCustomStringTreeOptions = class(TCustomVirtualTreeOptions)
  private
    FStringOptions: TVTStringOptions;
    procedure SetStringOptions(const Value: TVTStringOptions);
  protected
    property StringOptions: TVTStringOptions read FStringOptions write SetStringOptions default DefaultStringOptions;
  public
    constructor Create(AOwner: TBaseVirtualTree); override;

    procedure AssignTo(Dest: TPersistent); override;
  end;

  TStringTreeOptions = class(TCustomStringTreeOptions)
  published
    property AnimationOptions;
    property AutoOptions;
    property ExportMode;
    property MiscOptions;
    property PaintOptions;
    property SelectionOptions;
    property StringOptions;
  end;

  TCustomVirtualStringTree = class;
  
  TStringEditLink = class;

  {$ifdef TntSupport}
    TVTEdit = class(TTntEdit)
  {$else}
    TVTEdit = class(TCustomEdit)
  {$endif TntSupport}
  private
    procedure CMAutoAdjust(var Message: TMessage); message CM_AUTOADJUST;
    procedure CMExit(var Message: TMessage); message CM_EXIT;
    procedure CMRelease(var Message: TMessage); message CM_RELEASE;
    procedure CNCommand(var Message: TWMCommand); message CN_COMMAND;
    procedure WMChar(var Message: TWMChar); message WM_CHAR;
    procedure WMDestroy(var Message: TWMDestroy); message WM_DESTROY;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMKeyDown(var Message: TWMKeyDown); message WM_KEYDOWN;
  protected
    FRefLink: IVTEditLink;
    FLink: TStringEditLink;
    procedure AutoAdjustSize; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(Link: TStringEditLink); reintroduce;

    procedure Release; virtual;

    property AutoSelect;
    property AutoSize;
    property BorderStyle;
    property CharCase;
    property HideSelection;
    property MaxLength;
    property OEMConvert;
    property PasswordChar;
  end;

  TStringEditLink = class(TInterfacedObject, IVTEditLink)
  private
    FEdit: TVTEdit;                  
    procedure SetEdit(const Value: TVTEdit);
  protected
    FTree: TCustomVirtualStringTree; 
    FNode: PVirtualNode;             
    FColumn: TColumnIndex;           
    FAlignment: TAlignment;
    FTextBounds: TRect;              
    FStopping: Boolean;              
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function BeginEdit: Boolean; virtual; stdcall;
    function CancelEdit: Boolean; virtual; stdcall;
    property Edit: TVTEdit read FEdit write SetEdit;
    function EndEdit: Boolean; virtual; stdcall;
    function GetBounds: TRect; virtual; stdcall;
    function PrepareEdit(Tree: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex): Boolean; virtual; stdcall;
    procedure ProcessMessage(var Message: TMessage); virtual; stdcall;
    procedure SetBounds(R: TRect); virtual; stdcall;
  end;
  
  TVSTTextType = (
    ttNormal,      
    ttStatic       
  );
  
  TVSTTextSourceType = (
    tstAll,             
    tstInitialized,     
    tstSelected,        
    tstCutCopySet,      
    tstVisible,         
    tstChecked          
  );

  TVTPaintText = procedure(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
    TextType: TVSTTextType) of object;
  TVSTGetTextEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
    TextType: TVSTTextType; var CellText: UnicodeString) of object;
  TVSTGetHintEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
    var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: UnicodeString) of object;
  
  TVSTNewTextEvent = procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
    NewText: UnicodeString) of object;
  TVSTShortenStringEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
    Column: TColumnIndex; const S: UnicodeString; TextSpace: Integer; var Result: UnicodeString;
    var Done: Boolean) of object;
  TVTMeasureTextEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
    Column: TColumnIndex; const Text: UnicodeString; var Extent: Integer) of object;
  TVTDrawTextEvent = procedure(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
    Column: TColumnIndex; const Text: UnicodeString; const CellRect: TRect; var DefaultDraw: Boolean) of object;

  TCustomVirtualStringTree = class(TBaseVirtualTree)
  private
    FDefaultText: UnicodeString;                   
    FTextHeight: Integer;                          
    FEllipsisWidth: Integer;                       
    FInternalDataOffset: Cardinal;                 

    FOnPaintText: TVTPaintText;                    
                                                   
    FOnGetText: TVSTGetTextEvent;                  
    FOnGetHint: TVSTGetHintEvent;                  
    FOnNewText: TVSTNewTextEvent;                  
    FOnShortenString: TVSTShortenStringEvent;      
    FOnMeasureTextWidth: TVTMeasureTextEvent;      
    FOnMeasureTextHeight: TVTMeasureTextEvent;
    FOnDrawText: TVTDrawTextEvent;                 

    function GetImageText(Node: PVirtualNode; Kind: TVTImageKind;
      Column: TColumnIndex): UnicodeString;
    procedure GetRenderStartValues(Source: TVSTTextSourceType; var Node: PVirtualNode;
      var NextNodeProc: TGetNextNodeProc);
    function GetOptions: TCustomStringTreeOptions;
    function GetStaticText(Node: PVirtualNode; Column: TColumnIndex): UnicodeString;
    function GetText(Node: PVirtualNode; Column: TColumnIndex): UnicodeString;
    procedure InitializeTextProperties(var PaintInfo: TVTPaintInfo);
    procedure PaintNormalText(var PaintInfo: TVTPaintInfo; TextOutFlags: Integer; Text: UnicodeString);
    procedure PaintStaticText(const PaintInfo: TVTPaintInfo; TextOutFlags: Integer; const Text: UnicodeString);
    procedure ReadText(Reader: TReader);
    procedure SetDefaultText(const Value: UnicodeString);
    procedure SetOptions(const Value: TCustomStringTreeOptions);
    procedure SetText(Node: PVirtualNode; Column: TColumnIndex; const Value: UnicodeString);
    procedure WriteText(Writer: TWriter);

    procedure WMSetFont(var Msg: TWMSetFont); message WM_SETFONT;
    procedure GetDataFromGrid(const AStrings : TStringList; const IncludeHeading : Boolean=True);
  protected
    procedure AdjustPaintCellRect(var PaintInfo: TVTPaintInfo; var NextNonEmpty: TColumnIndex); override;
    function CanExportNode(Node: PVirtualNode): Boolean;
    function CalculateStaticTextWidth(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; Text: UnicodeString): Integer; virtual;
    function CalculateTextWidth(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; Text: UnicodeString): Integer; virtual;
    function ColumnIsEmpty(Node: PVirtualNode; Column: TColumnIndex): Boolean; override;
    procedure DefineProperties(Filer: TFiler); override;
    function DoCreateEditor(Node: PVirtualNode; Column: TColumnIndex): IVTEditLink; override;
    function DoGetNodeHint(Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle): UnicodeString; override;
    function DoGetNodeTooltip(Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle): UnicodeString; override;
    function DoGetNodeExtraWidth(Node: PVirtualNode; Column: TColumnIndex; Canvas: TCanvas = nil): Integer; override;
    function DoGetNodeWidth(Node: PVirtualNode; Column: TColumnIndex; Canvas: TCanvas = nil): Integer; override;
    procedure DoGetText(Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
      var Text: UnicodeString); virtual;
    function DoIncrementalSearch(Node: PVirtualNode; const Text: UnicodeString): Integer; override;
    procedure DoNewText(Node: PVirtualNode; Column: TColumnIndex; Text: UnicodeString); virtual;
    procedure DoPaintNode(var PaintInfo: TVTPaintInfo); override;
    procedure DoPaintText(Node: PVirtualNode; const Canvas: TCanvas; Column: TColumnIndex;
      TextType: TVSTTextType); virtual;
    function DoShortenString(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; const S: UnicodeString; Width: Integer;
      EllipsisWidth: Integer = 0): UnicodeString; virtual;
    procedure DoTextDrawing(var PaintInfo: TVTPaintInfo; Text: UnicodeString; CellRect: TRect; DrawFormat: Cardinal); virtual;
    function DoTextMeasuring(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; Text: UnicodeString): TSize; virtual;
    function GetOptionsClass: TTreeOptionsClass; override;
    function InternalData(Node: PVirtualNode): Pointer;
    procedure MainColumnChanged; override;
    function ReadChunk(Stream: TStream; Version: Integer; Node: PVirtualNode; ChunkType,
      ChunkSize: Integer): Boolean; override;
    procedure ReadOldStringOptions(Reader: TReader);
    function RenderOLEData(const FormatEtcIn: TFormatEtc; out Medium: TStgMedium; ForClipboard: Boolean): HResult; override;
    procedure WriteChunks(Stream: TStream; Node: PVirtualNode); override;

    property DefaultText: UnicodeString read FDefaultText write SetDefaultText stored False;
    property EllipsisWidth: Integer read FEllipsisWidth;
    property TreeOptions: TCustomStringTreeOptions read GetOptions write SetOptions;

    property OnGetHint: TVSTGetHintEvent read FOnGetHint write FOnGetHint;
    property OnGetText: TVSTGetTextEvent read FOnGetText write FOnGetText;
    property OnNewText: TVSTNewTextEvent read FOnNewText write FOnNewText;
    property OnPaintText: TVTPaintText read FOnPaintText write FOnPaintText;
    property OnShortenString: TVSTShortenStringEvent read FOnShortenString write FOnShortenString;
    property OnMeasureTextWidth: TVTMeasureTextEvent read FOnMeasureTextWidth write FOnMeasureTextWidth;
    property OnMeasureTextHeight: TVTMeasureTextEvent read FOnMeasureTextHeight write FOnMeasureTextHeight;
    property OnDrawText: TVTDrawTextEvent read FOnDrawText write FOnDrawText;
  public
    constructor Create(AOwner: TComponent); override;

    function ComputeNodeHeight(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; S: UnicodeString = ''): Integer; virtual;
    function ContentToClipboard(Format: Word; Source: TVSTTextSourceType): HGLOBAL;
    procedure ContentToCustom(Source: TVSTTextSourceType);
    function ContentToHTML(Source: TVSTTextSourceType; Caption: UnicodeString = ''): RawByteString;
    function ContentToRTF(Source: TVSTTextSourceType): RawByteString;
    function ContentToText(Source: TVSTTextSourceType; Separator: Char): AnsiString; overload;
    function ContentToText(Source: TVSTTextSourceType; const Separator: AnsiString): AnsiString; overload;
    function ContentToUnicode(Source: TVSTTextSourceType; Separator: WideChar): UnicodeString; overload;
    function ContentToUnicode(Source: TVSTTextSourceType; const Separator: UnicodeString): UnicodeString; overload;
    procedure GetTextInfo(Node: PVirtualNode; Column: TColumnIndex; const AFont: TFont; var R: TRect;
      var Text: UnicodeString); override;
    function InvalidateNode(Node: PVirtualNode): TRect; override;
    function Path(Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; Delimiter: WideChar): UnicodeString;
    procedure ReinitNode(Node: PVirtualNode; Recursive: Boolean); override;

    function SaveToCSVFile(const FileNameWithPath : TFileName; const IncludeHeading : Boolean) : Boolean;
    property ImageText[Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex]: UnicodeString read GetImageText;
    property StaticText[Node: PVirtualNode; Column: TColumnIndex]: UnicodeString read GetStaticText;
    property Text[Node: PVirtualNode; Column: TColumnIndex]: UnicodeString read GetText write SetText;
  end;

  TVirtualStringTree = class(TCustomVirtualStringTree)
  private
    function GetOptions: TStringTreeOptions;
    procedure SetOptions(const Value: TStringTreeOptions);
  protected
    function GetOptionsClass: TTreeOptionsClass; override;
  public
    property Canvas;
    property RangeX;
    property LastDragEffect;
  published
    property AccessibleName;
    property Action;
    property Align;
    property Alignment;
    property Anchors;
    property AnimationDuration;
    property AutoExpandDelay;
    property AutoScrollDelay;
    property AutoScrollInterval;
    property Background;
    property BackgroundOffsetX;
    property BackgroundOffsetY;
    property BiDiMode;
    property BevelEdges;
    property BevelInner;
    property BevelOuter;
    property BevelKind;
    property BevelWidth;
    property BorderStyle;
    property BottomSpace;
    property ButtonFillMode;
    property ButtonStyle;
    property BorderWidth;
    property ChangeDelay;
    property CheckImageKind;
    property ClipboardFormats;
    property Color;
    property Colors;
    property Constraints;
    property Ctl3D;
    property CustomCheckImages;
    property DefaultNodeHeight;
    property DefaultPasteMode;
    property DefaultText;
    property DragCursor;
    property DragHeight;
    property DragKind;
    property DragImageKind;
    property DragMode;
    property DragOperations;
    property DragType;
    property DragWidth;
    property DrawSelectionMode;
    property EditDelay;
    property EmptyListMessage;
    property Enabled;
    property Font;
    property Header;
    property HintAnimation;
    property HintMode;
    property HotCursor;
    property Images;
    property IncrementalSearch;
    property IncrementalSearchDirection;
    property IncrementalSearchStart;
    property IncrementalSearchTimeout;
    property Indent;
    property LineMode;
    property LineStyle;
    property Margin;
    property NodeAlignment;
    property NodeDataSize;
    property OperationCanceled;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property RootNodeCount;
    property ScrollBarOptions;
    property SelectionBlendFactor;
    property SelectionCurveRadius;
    property ShowHint;
    property StateImages;
    property TabOrder;
    property TabStop default True;
    property TextMargin;
    property TreeOptions: TStringTreeOptions read GetOptions write SetOptions;
    property Visible;
    property WantTabs;

    property OnAddToSelection;
    property OnAdvancedHeaderDraw;
    property OnAfterAutoFitColumn;
    property OnAfterAutoFitColumns;
    property OnAfterCellPaint;
    property OnAfterColumnExport;
    property OnAfterColumnWidthTracking;
    property OnAfterGetMaxColumnWidth;
    property OnAfterHeaderExport;
    property OnAfterHeaderHeightTracking;
    property OnAfterItemErase;
    property OnAfterItemPaint;
    property OnAfterNodeExport;
    property OnAfterPaint;
    property OnAfterTreeExport;
    property OnBeforeAutoFitColumn;
    property OnBeforeAutoFitColumns;
    property OnBeforeCellPaint;
    property OnBeforeColumnExport;
    property OnBeforeColumnWidthTracking;
    property OnBeforeDrawTreeLine;
    property OnBeforeGetMaxColumnWidth;
    property OnBeforeHeaderExport;
    property OnBeforeHeaderHeightTracking;
    property OnBeforeItemErase;
    property OnBeforeItemPaint;
    property OnBeforeNodeExport;
    property OnBeforePaint;
    property OnBeforeTreeExport;
    property OnCanSplitterResizeColumn;
    property OnCanSplitterResizeHeader;
    property OnCanSplitterResizeNode;
    property OnChange;
    property OnChecked;
    property OnChecking;
    property OnClick;
    property OnCollapsed;
    property OnCollapsing;
    property OnColumnClick;
    property OnColumnDblClick;
    property OnColumnExport;
    property OnColumnResize;
    property OnColumnWidthDblClickResize;
    property OnColumnWidthTracking;
    property OnCompareNodes;
    property OnContextPopup;
    property OnCreateDataObject;
    property OnCreateDragManager;
    property OnCreateEditor;
    property OnDblClick;
    property OnDragAllowed;
    property OnDragOver;
    property OnDragDrop;
    property OnDrawHint;
    property OnDrawText;
    property OnEditCancelled;
    property OnEdited;
    property OnEditing;
    property OnEndDock;
    property OnEndDrag;
    property OnEndOperation;
    property OnEnter;
    property OnExit;
    property OnExpanded;
    property OnExpanding;
    property OnFocusChanged;
    property OnFocusChanging;
    property OnFreeNode;
    property OnGetCellIsEmpty;
    property OnGetCursor;
    property OnGetHeaderCursor;
    property OnGetText;
    property OnPaintText;
    property OnGetHelpContext;
    property OnGetHintKind;
    property OnGetHintSize;
    property OnGetImageIndex;
    property OnGetImageIndexEx;
    property OnGetImageText;
    property OnGetHint;
    property OnGetLineStyle;
    property OnGetNodeDataSize;
    property OnGetPopupMenu;
    property OnGetUserClipboardFormats;
    property OnHeaderClick;
    property OnHeaderDblClick;
    property OnHeaderDragged;
    property OnHeaderDraggedOut;
    property OnHeaderDragging;
    property OnHeaderDraw;
    property OnHeaderDrawQueryElements;
    property OnHeaderHeightDblClickResize;
    property OnHeaderHeightTracking;
    property OnHeaderMouseDown;
    property OnHeaderMouseMove;
    property OnHeaderMouseUp;
    property OnHotChange;
    property OnIncrementalSearch;
    property OnInitChildren;
    property OnInitNode;
    property OnKeyAction;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLoadNode;
    property OnLoadTree;
    property OnMeasureItem;
    property OnMeasureTextWidth;
    property OnMeasureTextHeight;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnNewText;
    property OnNodeClick;
    property OnNodeCopied;
    property OnNodeCopying;
    property OnNodeDblClick;
    property OnNodeExport;
    property OnNodeHeightDblClickResize;
    property OnNodeHeightTracking;
    property OnNodeMoved;
    property OnNodeMoving;
    property OnPaintBackground;
    property OnRemoveFromSelection;
    property OnRenderOLEData;
    property OnResetNode;
    property OnResize;
    property OnSaveNode;
    property OnSaveTree;
    property OnScroll;
    property OnShortenString;
    property OnShowScrollbar;
    property OnStartDock;
    property OnStartDrag;
    property OnStartOperation;
    property OnStateChange;
    property OnStructureChange;
    property OnUpdating;
    {$if CompilerVersion>=22}
    property OnCanResize;
    property OnGesture;
    property Touch;
    {$ifend}
  end;

  TVTDrawNodeEvent = procedure(Sender: TBaseVirtualTree; const PaintInfo: TVTPaintInfo) of object;
  TVTGetCellContentMarginEvent = procedure(Sender: TBaseVirtualTree; HintCanvas: TCanvas; Node: PVirtualNode;
    Column: TColumnIndex; CellContentMarginType: TVTCellContentMarginType; var CellContentMargin: TPoint) of object;
  TVTGetNodeWidthEvent = procedure(Sender: TBaseVirtualTree; HintCanvas: TCanvas; Node: PVirtualNode;
    Column: TColumnIndex; var NodeWidth: Integer) of object;
  
  TCustomVirtualDrawTree = class(TBaseVirtualTree)
  private
    FOnDrawNode: TVTDrawNodeEvent;
    FOnGetCellContentMargin: TVTGetCellContentMarginEvent;
    FOnGetNodeWidth: TVTGetNodeWidthEvent;
  protected
    function DoGetCellContentMargin(Node: PVirtualNode; Column: TColumnIndex;
      CellContentMarginType: TVTCellContentMarginType = ccmtAllSides; Canvas: TCanvas = nil): TPoint; override;
    function DoGetNodeWidth(Node: PVirtualNode; Column: TColumnIndex; Canvas: TCanvas = nil): Integer; override;
    procedure DoPaintNode(var PaintInfo: TVTPaintInfo); override;
    function GetDefaultHintKind: TVTHintKind; override;

    property OnDrawNode: TVTDrawNodeEvent read FOnDrawNode write FOnDrawNode;
    property OnGetCellContentMargin: TVTGetCellContentMarginEvent read FOnGetCellContentMargin write FOnGetCellContentMargin;
    property OnGetNodeWidth: TVTGetNodeWidthEvent read FOnGetNodeWidth write FOnGetNodeWidth;
  end;

  TVirtualDrawTree = class(TCustomVirtualDrawTree)
  private
    function GetOptions: TVirtualTreeOptions;
    procedure SetOptions(const Value: TVirtualTreeOptions);
  protected
    function GetOptionsClass: TTreeOptionsClass; override;
  public
    property Canvas;
    property LastDragEffect;
  published
    property Action;
    property Align;
    property Alignment;
    property Anchors;
    property AnimationDuration;
    property AutoExpandDelay;
    property AutoScrollDelay;
    property AutoScrollInterval;
    property Background;
    property BackgroundOffsetX;
    property BackgroundOffsetY;
    property BiDiMode;
    property BevelEdges;
    property BevelInner;
    property BevelOuter;
    property BevelKind;
    property BevelWidth;
    property BorderStyle;
    property BottomSpace;
    property ButtonFillMode;
    property ButtonStyle;
    property BorderWidth;
    property ChangeDelay;
    property CheckImageKind;
    property ClipboardFormats;
    property Color;
    property Colors;
    property Constraints;
    property Ctl3D;
    property CustomCheckImages;
    property DefaultNodeHeight;
    property DefaultPasteMode;
    property DragCursor;
    property DragHeight;
    property DragKind;
    property DragImageKind;
    property DragMode;
    property DragOperations;
    property DragType;
    property DragWidth;
    property DrawSelectionMode;
    property EditDelay;
    property Enabled;
    property Font;
    property Header;
    property HintAnimation;
    property HintMode;
    property HotCursor;
    property Images;
    property IncrementalSearch;
    property IncrementalSearchDirection;
    property IncrementalSearchStart;
    property IncrementalSearchTimeout;
    property Indent;
    property LineMode;
    property LineStyle;
    property Margin;
    property NodeAlignment;
    property NodeDataSize;
    property OperationCanceled;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property RootNodeCount;
    property ScrollBarOptions;
    property SelectionBlendFactor;
    property SelectionCurveRadius;
    property ShowHint;
    property StateImages;
    property TabOrder;
    property TabStop default True;
    property TextMargin;
    property TreeOptions: TVirtualTreeOptions read GetOptions write SetOptions;
    property Visible;
    property WantTabs;

    property OnAddToSelection;
    property OnAdvancedHeaderDraw;
    property OnAfterAutoFitColumn;
    property OnAfterAutoFitColumns;
    property OnAfterCellPaint;
    property OnAfterColumnExport;
    property OnAfterColumnWidthTracking;
    property OnAfterGetMaxColumnWidth;
    property OnAfterHeaderExport;
    property OnAfterHeaderHeightTracking;
    property OnAfterItemErase;
    property OnAfterItemPaint;
    property OnAfterNodeExport;
    property OnAfterPaint;
    property OnAfterTreeExport;
    property OnBeforeAutoFitColumn;
    property OnBeforeAutoFitColumns;
    property OnBeforeCellPaint;
    property OnBeforeColumnExport;
    property OnBeforeColumnWidthTracking;
    property OnBeforeDrawTreeLine;
    property OnBeforeGetMaxColumnWidth;
    property OnBeforeHeaderExport;
    property OnBeforeHeaderHeightTracking;
    property OnBeforeItemErase;
    property OnBeforeItemPaint;
    property OnBeforeNodeExport;
    property OnBeforePaint;
    property OnBeforeTreeExport;
    property OnCanSplitterResizeColumn;
    property OnCanSplitterResizeHeader;
    property OnCanSplitterResizeNode;
    property OnChange;
    property OnChecked;
    property OnChecking;
    property OnClick;
    property OnCollapsed;
    property OnCollapsing;
    property OnColumnClick;
    property OnColumnDblClick;
    property OnColumnExport;
    property OnColumnResize;
    property OnColumnWidthDblClickResize;
    property OnColumnWidthTracking;
    property OnCompareNodes;
    property OnContextPopup;
    property OnCreateDataObject;
    property OnCreateDragManager;
    property OnCreateEditor;
    property OnDblClick;
    property OnDragAllowed;
    property OnDragOver;
    property OnDragDrop;
    property OnDrawHint;
    property OnDrawNode;
    property OnEdited;
    property OnEditing;
    property OnEndDock;
    property OnEndDrag;
    property OnEndOperation;
    property OnEnter;
    property OnExit;
    property OnExpanded;
    property OnExpanding;
    property OnFocusChanged;
    property OnFocusChanging;
    property OnFreeNode;
    property OnGetCellIsEmpty;
    property OnGetCursor;
    property OnGetHeaderCursor;
    property OnGetHelpContext;
    property OnGetHintKind;
    property OnGetHintSize;
    property OnGetImageIndex;
    property OnGetImageIndexEx;
    property OnGetLineStyle;
    property OnGetNodeDataSize;
    property OnGetNodeWidth;
    property OnGetPopupMenu;
    property OnGetUserClipboardFormats;
    property OnHeaderClick;
    property OnHeaderDblClick;
    property OnHeaderDragged;
    property OnHeaderDraggedOut;
    property OnHeaderDragging;
    property OnHeaderDraw;
    property OnHeaderDrawQueryElements;
    property OnHeaderHeightTracking;
    property OnHeaderHeightDblClickResize;
    property OnHeaderMouseDown;
    property OnHeaderMouseMove;
    property OnHeaderMouseUp;
    property OnHotChange;
    property OnIncrementalSearch;
    property OnInitChildren;
    property OnInitNode;
    property OnKeyAction;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLoadNode;
    property OnLoadTree;
    property OnMeasureItem;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnNodeClick;
    property OnNodeCopied;
    property OnNodeCopying;
    property OnNodeDblClick;
    property OnNodeExport;
    property OnNodeHeightTracking;
    property OnNodeHeightDblClickResize;
    property OnNodeMoved;
    property OnNodeMoving;
    property OnPaintBackground;
    property OnRemoveFromSelection;
    property OnRenderOLEData;
    property OnResetNode;
    property OnResize;
    property OnSaveNode;
    property OnSaveTree;
    property OnScroll;
    property OnShowScrollbar;
    property OnStartDock;
    property OnStartDrag;
    property OnStartOperation;
    property OnStateChange;
    property OnStructureChange;
    property OnUpdating;
    {$if CompilerVersion>=22}
    property OnCanResize;
    property OnGesture;
    property Touch;
    {$ifend}
  end;

type
  
  TBlendMode = (
    bmConstantAlpha,         
    bmPerPixelAlpha,         
    bmMasterAlpha,           
    bmConstantAlphaAndColor  
  );

procedure EnumerateVTClipboardFormats(TreeClass: TVirtualTreeClass; const List: TStrings); overload;
procedure EnumerateVTClipboardFormats(TreeClass: TVirtualTreeClass; var Formats: TFormatEtcArray); overload;
function GetVTClipboardFormatDescription(AFormat: Word): string;
procedure RegisterVTClipboardFormat(AFormat: Word; TreeClass: TVirtualTreeClass; Priority: Cardinal); overload;
function RegisterVTClipboardFormat(Description: string; TreeClass: TVirtualTreeClass; Priority: Cardinal;
  tymed: Integer = TYMED_HGLOBAL; ptd: PDVTargetDevice = nil; dwAspect: Integer = DVASPECT_CONTENT;
  lindex: Integer = -1): Word; overload;

procedure AlphaBlend(Source, Destination: HDC; R: TRect; Target: TPoint; Mode: TBlendMode; ConstantAlpha, Bias: Integer);
procedure PrtStretchDrawDIB(Canvas: TCanvas; DestRect: TRect; ABitmap: TBitmap);
function ShortenString(DC: HDC; const S: UnicodeString; Width: Integer; EllipsisWidth: Integer = 0): UnicodeString;
function TreeFromNode(Node: PVirtualNode): TBaseVirtualTree;
procedure GetStringDrawRect(DC: HDC; const S: UnicodeString; var Bounds: TRect; DrawFormat: Cardinal);
function WrapString(DC: HDC; const S: UnicodeString; const Bounds: TRect; RTL: Boolean;
  DrawFormat: Cardinal): UnicodeString;

implementation

{$R VirtualTrees.res}

uses
  Consts, Math,
  AxCtrls,                 
  MMSystem,                
  TypInfo,                 
  ActnList,
  StdActns,                
  {$ifdef UNICODE}
  AnsiStrings,
  {$endif UNICODE}
  StrUtils,
  VTAccessibilityFactory, GraphUtil;  

resourcestring
  
  SEditLinkIsNil = 'Edit link must not be nil.';
  SWrongMoveError = 'Target node cannot be a child node of the node to be moved.';
  SWrongStreamFormat = 'Unable to load tree structure, the format is wrong.';
  SWrongStreamVersion = 'Unable to load tree structure, the version is unknown.';
  SStreamTooSmall = 'Unable to load tree structure, not enough data available.';
  SCorruptStream1 = 'Stream data corrupt. A node''s anchor chunk is missing.';
  SCorruptStream2 = 'Stream data corrupt. Unexpected data after node''s end position.';
  SClipboardFailed = 'Clipboard operation failed.';
  SCannotSetUserData = 'Cannot set initial user data because there is not enough user data space allocated.';

const
  ClipboardStates = [tsCopyPending, tsCutPending];
  DefaultScrollUpdateFlags = [suoRepaintHeader, suoRepaintScrollbars, suoScrollClientArea, suoUpdateNCArea];
  TreeNodeSize = (SizeOf(TVirtualNode) + (SizeOf(Pointer) - 1)) and not (SizeOf(Pointer) - 1); 
  
  PressedState: array[TCheckState] of TCheckState = (
    csUncheckedPressed, csUncheckedPressed, csCheckedPressed, csCheckedPressed, csMixedPressed, csMixedPressed
  );
  UnpressedState: array[TCheckState] of TCheckState = (
    csUncheckedNormal, csUncheckedNormal, csCheckedNormal, csCheckedNormal, csMixedNormal, csMixedNormal
  );
  MouseButtonDown = [tsLeftButtonDown, tsMiddleButtonDown, tsRightButtonDown];
  
  Copyright: string = 'Virtual Treeview ?1999, 2010 Mike Lischke';

var
  StandardOLEFormat: TFormatEtc = (
    
    cfFormat: 0;
    
    ptd: nil;
    
    dwAspect: DVASPECT_CONTENT;
    
    lindex: -1;
    
    tymed: TYMED_ISTREAM or TYMED_HGLOBAL;
  );

  {$if CompilerVersion < 23}
type
  TElementEdge = (
    eeRaisedOuter
  );

  TElementEdges = set of TElementEdge;

  TElementEdgeFlag = (
    efRect
  );

  TElementEdgeFlags = set of TElementEdgeFlag;
  
  StyleServices = class
    class function Enabled: Boolean;
    class function DrawEdge(DC: HDC; Details: TThemedElementDetails; const R: TRect;
      Edges: TElementEdges; Flags: TElementEdgeFlags; ContentRect: PRect = nil): Boolean;
    class function DrawElement(DC: HDC; Details: TThemedElementDetails; const R: TRect; ClipRect: PRect = nil): Boolean;
    class function GetElementDetails(Detail: TThemedHeader): TThemedElementDetails; overload;
    class function GetElementDetails(Detail: TThemedToolTip): TThemedElementDetails; overload;
    class function GetElementDetails(Detail: TThemedWindow): TThemedElementDetails; overload;
    class function GetElementDetails(Detail: TThemedButton): TThemedElementDetails; overload;
    class procedure PaintBorder(Control: TWinControl; EraseLRCorner: Boolean);
  end;

  class function StyleServices.Enabled: Boolean;
  begin
    Result := ThemeServices.ThemesEnabled;
  end;

  class function StyleServices.DrawEdge(DC: HDC; Details: TThemedElementDetails; const R: TRect;
    Edges: TElementEdges; Flags: TElementEdgeFlags; ContentRect: PRect = nil): Boolean;
  begin
    Assert((Edges = [eeRaisedOuter]) and (Flags = [efRect]));
    ThemeServices.DrawEdge(DC, Details, R, BDR_RAISEDOUTER, BF_RECT);
    Result := Enabled;
  end;

  class function StyleServices.DrawElement(DC: HDC; Details: TThemedElementDetails; const R: TRect; ClipRect: PRect = nil): Boolean;
  begin
    ThemeServices.DrawElement(DC, Details, R, ClipRect);
    Result := Enabled;
  end;

  class function StyleServices.GetElementDetails(Detail: TThemedHeader): TThemedElementDetails;
  begin
    Result := ThemeServices.GetElementDetails(Detail);
  end;

  class function StyleServices.GetElementDetails(Detail: TThemedToolTip): TThemedElementDetails;
  begin
    Result := ThemeServices.GetElementDetails(Detail);
  end;

  class function StyleServices.GetElementDetails(Detail: TThemedWindow): TThemedElementDetails;
  begin
    Result := ThemeServices.GetElementDetails(Detail);
  end;

  class function StyleServices.GetElementDetails(Detail: TThemedButton): TThemedElementDetails;
  begin
    Result := ThemeServices.GetElementDetails(Detail);
  end;

  class procedure StyleServices.PaintBorder(Control: TWinControl; EraseLRCorner: Boolean);
  begin
    ThemeServices.PaintBorder(Control, EraseLRCorner);
  end;
  {$ifend}

type
  
  TWithSafeRect = record
    case Integer of
      0: (Left, Top, Right, Bottom: Longint);
      1: (TopLeft, BottomRight: TPoint);
  end;

type 
  TMagicID = array[0..5] of WideChar;

  TChunkHeader = record
    ChunkType,
    ChunkSize: Integer;      
  end;
  
  TBaseChunkBody = packed record
    ChildCount,
    NodeHeight: Cardinal;
    States: TVirtualNodeStates;
    Align: Byte;
    CheckState: TCheckState;
    CheckType: TCheckType;
    Reserved: Cardinal;
  end;

  TBaseChunk = packed record
    Header: TChunkHeader;
    Body: TBaseChunkBody;
  end;
  
  TToggleAnimationMode = (
    tamScrollUp,
    tamScrollDown,
    tamNoScroll
  );
  
  TToggleAnimationData = record
    Window: HWND;                 
    DC: HDC;                      
    Brush: HBRUSH;                
    R1,
    R2: TRect;                    
    Mode1,
    Mode2: TToggleAnimationMode;  
    ScaleFactor: Double;          
    MissedSteps: Double;
  end;

  TCanvasEx = class(TCanvas);

const
  MagicID: TMagicID = (#$2045, 'V', 'T', WideChar(VTTreeStreamVersion), ' ', #$2046);
  
  NodeChunk = 1;
  BaseChunk = 2;        
                        
  CaptionChunk = 3;     
  UserChunk = 4;        

  {$if CompilerVersion < 19}
    const
      TVP_HOTGLYPH = 4;
  {$ifend}

  RTLFlag: array[Boolean] of Integer = (0, ETO_RTLREADING);
  AlignmentToDrawFlag: array[TAlignment] of Cardinal = (DT_LEFT, DT_RIGHT, DT_CENTER);

  WideNull = WideChar(#0);
  WideCR = WideChar(#13);
  WideLF = WideChar(#10);
  WideLineSeparator = WideChar(#2028);

type
  TCriticalSection = class(TObject)
  protected
    FSection: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Enter;
    procedure Leave;
  end;
  
  TWorkerThread = class(TThread)
  private
    FCurrentTree: TBaseVirtualTree;
    FWaiterList: TThreadList;
    FRefCount: Cardinal;
  protected
    procedure CancelValidation(Tree: TBaseVirtualTree);
    procedure ChangeTreeStates(EnterStates, LeaveStates: TChangeStates);
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;

    procedure AddTree(Tree: TBaseVirtualTree);
    procedure RemoveTree(Tree: TBaseVirtualTree);

    property CurrentTree: TBaseVirtualTree read FCurrentTree;
  end;
  
  TBufferedAnsiString = class
  private
    FStart,
    FPosition,
    FEnd: PAnsiChar;
    function GetAsString: RawByteString;
  public
    destructor Destroy; override;

    procedure Add(const S: RawByteString);
    procedure AddNewLine;

    property AsString: RawByteString read GetAsString;
  end;

  TWideBufferedString = class
  private
    FStart,
    FPosition,
    FEnd: PWideChar;
    function GetAsString: UnicodeString;
  public
    destructor Destroy; override;

    procedure Add(const S: UnicodeString);
    procedure AddNewLine;

    property AsString: UnicodeString read GetAsString;
  end;

var
  WorkerThread: TWorkerThread;
  WorkEvent: THandle;
  Watcher: TCriticalSection;
  LightCheckImages,                    
  DarkCheckImages,                     
  LightTickImages,                     
  DarkTickImages,                      
  FlatImages,                          
  XPImages,                            
  UtilityImages,                       
  SystemCheckImages,                   
  SystemFlatCheckImages: TImageList;   
  Initialized: Boolean;                
  NeedToUnitialize: Boolean;           

type
  PClipboardFormatListEntry = ^TClipboardFormatListEntry;
  TClipboardFormatListEntry = record
    Description: string;               
    TreeClass: TVirtualTreeClass;      
    Priority: Cardinal;                
    FormatEtc: TFormatEtc;             
  end;

  TClipboardFormatList = class
  private
    FList: TList;
    procedure Sort;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(FormatString: string; AClass: TVirtualTreeClass; Priority: Cardinal; AFormatEtc: TFormatEtc);
    procedure Clear;
    procedure EnumerateFormats(TreeClass: TVirtualTreeClass; var Formats: TFormatEtcArray;
      const AllowedFormats: TClipboardFormats = nil); overload;
    procedure EnumerateFormats(TreeClass: TVirtualTreeClass; const Formats: TStrings); overload;
    function FindFormat(FormatString: string): PClipboardFormatListEntry; overload;
    function FindFormat(FormatString: string; var Fmt: Word): TVirtualTreeClass; overload;
    function FindFormat(Fmt: Word; var Description: string): TVirtualTreeClass; overload;
  end;

var
  InternalClipboardFormats: TClipboardFormatList;

constructor TClipboardFormatList.Create;

begin
  FList := TList.Create;
end;

destructor TClipboardFormatList.Destroy;

begin
  Clear;
  FList.Free;
  inherited;
end;

procedure TClipboardFormatList.Sort;

  procedure QuickSort(L, R: Integer);

  var
    I, J: Integer;
    P, T: PClipboardFormatListEntry;

  begin
    repeat
      I := L;
      J := R;
      P := FList[(L + R) shr 1];
      repeat
        while PClipboardFormatListEntry(FList[I]).Priority < P.Priority do
          Inc(I);
        while PClipboardFormatListEntry(Flist[J]).Priority > P.Priority do
          Dec(J);
        if I <= J then
        begin
          T := Flist[I];
          FList[I] := FList[J];
          FList[J] := T;
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if L < J then
        QuickSort(L, J);
      L := I;
    until I >= R;
  end;

begin
  if FList.Count > 1 then
    QuickSort(0, FList.Count - 1);
end;

procedure TClipboardFormatList.Add(FormatString: string; AClass: TVirtualTreeClass; Priority: Cardinal;
  AFormatEtc: TFormatEtc);

var
  Entry: PClipboardFormatListEntry;

begin
  New(Entry);
  Entry.Description := FormatString;
  Entry.TreeClass := AClass;
  Entry.Priority := Priority;
  Entry.FormatEtc := AFormatEtc;
  FList.Add(Entry);

  Sort;
end;

procedure TClipboardFormatList.Clear;

var
  I: Integer;

begin
  for I := 0 to FList.Count - 1 do
    Dispose(PClipboardFormatListEntry(FList[I]));
  FList.Clear;
end;

procedure TClipboardFormatList.EnumerateFormats(TreeClass: TVirtualTreeClass; var Formats: TFormatEtcArray;
  const AllowedFormats: TClipboardFormats = nil);

var
  I, Count: Integer;
  Entry: PClipboardFormatListEntry;

begin
  SetLength(Formats, FList.Count);
  Count := 0;
  for I := 0 to FList.Count - 1 do
  begin
    Entry := FList[I];
    
    if TreeClass.InheritsFrom(Entry.TreeClass) then
    begin
      
      if (AllowedFormats = nil) or (AllowedFormats.IndexOf(Entry.Description) > -1) then
      begin
        
        Formats[Count] := Entry.FormatEtc;
        Inc(Count);
      end;
    end;
  end;
  SetLength(Formats, Count);
end;

procedure TClipboardFormatList.EnumerateFormats(TreeClass: TVirtualTreeClass; const Formats: TStrings);

var
  I: Integer;
  Entry: PClipboardFormatListEntry;

begin
  for I := 0 to FList.Count - 1 do
  begin
    Entry := FList[I];
    if TreeClass.InheritsFrom(Entry.TreeClass) then
      Formats.Add(Entry.Description);
  end;
end;

function TClipboardFormatList.FindFormat(FormatString: string): PClipboardFormatListEntry;

var
  I: Integer;
  Entry: PClipboardFormatListEntry;

begin
  Result := nil;
  for I := FList.Count - 1 downto 0 do
  begin
    Entry := FList[I];
    if CompareText(Entry.Description, FormatString) = 0 then
    begin
      Result := Entry;
      Break;
    end;
  end;
end;

function TClipboardFormatList.FindFormat(FormatString: string; var Fmt: Word): TVirtualTreeClass;

var
  I: Integer;
  Entry: PClipboardFormatListEntry;

begin
  Result := nil;
  for I := FList.Count - 1 downto 0 do
  begin
    Entry := FList[I];
    if CompareText(Entry.Description, FormatString) = 0 then
    begin
      Result := Entry.TreeClass;
      Fmt := Entry.FormatEtc.cfFormat;
      Break;
    end;
  end;
end;

function TClipboardFormatList.FindFormat(Fmt: Word; var Description: string): TVirtualTreeClass;

var
  I: Integer;
  Entry: PClipboardFormatListEntry;

begin
  Result := nil;
  for I := FList.Count - 1 downto 0 do
  begin
    Entry := FList[I];
    if Entry.FormatEtc.cfFormat = Fmt then
    begin
      Result := Entry.TreeClass;
      Description := Entry.Description;
      Break;
    end;
  end;
end;

type
  TClipboardFormatEntry = record
    ID: Word;
    Description: string;
  end;

var
  ClipboardDescriptions: array [1..CF_MAX - 1] of TClipboardFormatEntry = (
    (ID: CF_TEXT; Description: 'Plain text'), 
    (ID: CF_BITMAP; Description: 'Windows bitmap'), 
    (ID: CF_METAFILEPICT; Description: 'Windows metafile'), 
    (ID: CF_SYLK; Description: 'Symbolic link'), 
    (ID: CF_DIF; Description: 'Data interchange format'), 
    (ID: CF_TIFF; Description: 'Tiff image'), 
    (ID: CF_OEMTEXT; Description: 'OEM text'), 
    (ID: CF_DIB; Description: 'DIB image'), 
    (ID: CF_PALETTE; Description: 'Palette data'), 
    (ID: CF_PENDATA; Description: 'Pen data'), 
    (ID: CF_RIFF; Description: 'Riff audio data'), 
    (ID: CF_WAVE; Description: 'Wav audio data'), 
    (ID: CF_UNICODETEXT; Description: 'Unicode text'), 
    (ID: CF_ENHMETAFILE; Description: 'Enhanced metafile image'), 
    (ID: CF_HDROP; Description: 'File name(s)'), 
    (ID: CF_LOCALE; Description: 'Locale descriptor') 
    {$if CompilerVersion >= 23}
    ,(ID: CF_DIBV5; Description: 'DIB image V5') 
    {$ifend}
  );

procedure EnumerateVTClipboardFormats(TreeClass: TVirtualTreeClass; const List: TStrings);

begin
  if InternalClipboardFormats = nil then
    InternalClipboardFormats := TClipboardFormatList.Create;
  InternalClipboardFormats.EnumerateFormats(TreeClass, List);
end;

procedure EnumerateVTClipboardFormats(TreeClass: TVirtualTreeClass; var Formats: TFormatEtcArray);

begin
  if InternalClipboardFormats = nil then
    InternalClipboardFormats := TClipboardFormatList.Create;
  InternalClipboardFormats.EnumerateFormats(TreeClass, Formats);
end;

function GetVTClipboardFormatDescription(AFormat: Word): string;

begin
  if InternalClipboardFormats = nil then
    InternalClipboardFormats := TClipboardFormatList.Create;
  if InternalClipboardFormats.FindFormat(AFormat, Result) = nil then
    Result := '';
end;

procedure RegisterVTClipboardFormat(AFormat: Word; TreeClass: TVirtualTreeClass; Priority: Cardinal);

var
  I: Integer;
  Buffer: array[0..2048] of Char;
  FormatEtc: TFormatEtc;

begin
  if InternalClipboardFormats = nil then
    InternalClipboardFormats := TClipboardFormatList.Create;
  
  FormatEtc.cfFormat := AFormat;
  FormatEtc.ptd := nil;
  FormatEtc.dwAspect := DVASPECT_CONTENT;
  FormatEtc.lindex := -1;
  FormatEtc.tymed := TYMED_HGLOBAL;
  
  if AFormat < CF_MAX then
  begin
    for I := 1 to High(ClipboardDescriptions) do
      if ClipboardDescriptions[I].ID = AFormat then
      begin
        InternalClipboardFormats.Add(ClipboardDescriptions[I].Description, TreeClass, Priority, FormatEtc);
        Break;
      end;
  end
  else
  begin
    GetClipboardFormatName(AFormat, Buffer, Length(Buffer));
    InternalClipboardFormats.Add(Buffer, TreeClass, Priority, FormatEtc);
  end;
end;

function RegisterVTClipboardFormat(Description: string; TreeClass: TVirtualTreeClass; Priority: Cardinal;
  tymed: Integer = TYMED_HGLOBAL; ptd: PDVTargetDevice = nil; dwAspect: Integer = DVASPECT_CONTENT;
  lindex: Integer = -1): Word;

var
  FormatEtc: TFormatEtc;

begin
  if InternalClipboardFormats = nil then
    InternalClipboardFormats := TClipboardFormatList.Create;
  Result := RegisterClipboardFormat(PChar(Description));
  FormatEtc.cfFormat := Result;
  FormatEtc.ptd := ptd;
  FormatEtc.dwAspect := dwAspect;
  FormatEtc.lindex := lindex;
  FormatEtc.tymed := tymed;
  InternalClipboardFormats.Add(Description, TreeClass, Priority, FormatEtc);
end;

procedure ShowError(Msg: UnicodeString; HelpContext: Integer);

begin
  raise EVirtualTreeError.CreateHelp(Msg, HelpContext);
end;

function TreeFromNode(Node: PVirtualNode): TBaseVirtualTree;

begin
  Assert(Assigned(Node), 'Node must not be nil.');
  
  while Assigned(Node) and (Node.NextSibling <> Node) do
    Node := Node.Parent;
  if Assigned(Node) then
    Result := TBaseVirtualTree(Node.Parent)
  else
    Result := nil;
end;

function OrderRect(const R: TRect): TRect;

begin
  if R.Left < R.Right then
  begin
    Result.Left := R.Left;
    Result.Right := R.Right;
  end
  else
  begin
    Result.Left := R.Right;
    Result.Right := R.Left;
  end;
  if R.Top < R.Bottom then
  begin
    Result.Top := R.Top;
    Result.Bottom := R.Bottom;
  end
  else
  begin
    Result.Top := R.Bottom;
    Result.Bottom := R.Top;
  end;
end;

procedure QuickSort(const TheArray: TNodeArray; L, R: Integer);

var
  I, J: Integer;
  P, T: Pointer;

begin
  repeat
    I := L;
    J := R;
    P := TheArray[(L + R) shr 1];
    repeat
      while PAnsiChar(TheArray[I]) < PAnsiChar(P) do
        Inc(I);
      while PAnsiChar(TheArray[J]) > PAnsiChar(P) do
        Dec(J);
      if I <= J then
      begin
        T := TheArray[I];
        TheArray[I] := TheArray[J];
        TheArray[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(TheArray, L, J);
    L := I;
  until I >= R;
end;

function ShortenString(DC: HDC; const S: UnicodeString; Width: Integer; EllipsisWidth: Integer = 0): UnicodeString;

var
  Size: TSize;
  Len: Integer;
  L, H, N, W: Integer;

begin
  Len := Length(S);
  if (Len = 0) or (Width <= 0) then
    Result := ''
  else
  begin
    
    if EllipsisWidth = 0 then
    begin
      GetTextExtentPoint32W(DC, '...', 3, Size);
      EllipsisWidth := Size.cx;
    end;

    if Width <= EllipsisWidth then
      Result := ''
    else
    begin
      
      L := 0;
      H := Len - 1;
      while L < H do
      begin
        N := (L + H + 1) shr 1;
        GetTextExtentPoint32W(DC, PWideChar(S), N, Size);
        W := Size.cx + EllipsisWidth;
        if W <= Width then
          L := N
        else
          H := N - 1;
      end;
      Result := Copy(S, 1, L) + '...'
    end;
  end;
end;

function WrapString(DC: HDC; const S: UnicodeString; const Bounds: TRect; RTL: Boolean;
  DrawFormat: Cardinal): UnicodeString;

var
  Width,
  Len,
  WordCounter,
  WordsInLine,
  I, W: Integer;
  Buffer,
  Line: UnicodeString;
  Words: Array of UnicodeString;
  R: TRect;

begin
  Result := '';
  Width := Bounds.Right - Bounds.Left;
  R := Rect(0, 0, 0, 0);
  
  Buffer := Trim(S);
  Len := Length(Buffer);
  if Len < 1 then
    Exit;
  
  WordCounter := 1;
  for I := 1 to Len do
    if Buffer[I] = ' ' then
      Inc(WordCounter);
  SetLength(Words, WordCounter);

  if RTL then
  begin
    
    W := 0;
    for I := 1 to Len do
      if Buffer[I] = ' ' then
        Inc(W)
      else
        Words[W] := Words[W] + Buffer[I];
    
    while WordCounter > 0 do
    begin
      WordsInLine := 0;
      Line := '';

      while WordCounter > 0 do
      begin
        GetStringDrawRect(DC, Line + IfThen(WordsInLine > 0, ' ', '') + Words[WordCounter - 1], R, DrawFormat);
        if R.Right > Width then
        begin
          
          if WordsInLine > 0 then
            Break;

          Buffer := Words[WordCounter - 1];
          if Len > 1 then
          begin
            for Len := Length(Buffer) - 1 downto 2 do
            begin
              GetStringDrawRect(DC, RightStr(Buffer, Len), R, DrawFormat);
              if R.Right <= Width then
                Break;
            end;
          end
          else
            Len := Length(Buffer);

          Line := Line + RightStr(Buffer, Max(Len, 1));
          Words[WordCounter - 1] := LeftStr(Buffer, Length(Buffer) - Max(Len, 1));
          if Words[WordCounter - 1] = '' then
            Dec(WordCounter);
          Break;
        end
        else
        begin
          Dec(WordCounter);
          Line := Words[WordCounter] + IfThen(WordsInLine > 0, ' ', '') + Line;
          Inc(WordsInLine);
        end;
      end;

      Result := Result + Line + WideLF;
    end;
  end
  else
  begin
    
    W := WordCounter - 1;
    for I := 1 to Len do
      if Buffer[I] = ' ' then
        Dec(W)
      else
        Words[W] := Words[W] + Buffer[I];
    
    while WordCounter > 0 do
    begin
      WordsInLine := 0;
      Line := '';

      while WordCounter > 0 do
      begin
        GetStringDrawRect(DC, Line + IfThen(WordsInLine > 0, ' ', '') + Words[WordCounter - 1], R, DrawFormat);
        if R.Right > Width then
        begin
          
          if WordsInLine > 0 then
            Break;

          Buffer := Words[WordCounter - 1];
          if Len > 1 then
          begin
            for Len := Length(Buffer) - 1 downto 2 do
            begin
              GetStringDrawRect(DC, LeftStr(Buffer, Len), R, DrawFormat);
              if R.Right <= Width then
                Break;
            end;
          end
          else
            Len := Length(Buffer);

          Line := Line + LeftStr(Buffer, Max(Len, 1));
          Words[WordCounter - 1] := RightStr(Buffer, Length(Buffer) - Max(Len, 1));
          if Words[WordCounter - 1] = '' then
            Dec(WordCounter);
          Break;
        end
        else
        begin
          Dec(WordCounter);
          Line := Line + IfThen(WordsInLine > 0, ' ', '') + Words[WordCounter];
          Inc(WordsInLine);
        end;
      end;

      Result := Result + Line + WideLF;
    end;
  end;

  Len := Length(Result);
  if Result[Len] = WideLF then
    SetLength(Result, Len - 1);
end;

procedure GetStringDrawRect(DC: HDC; const S: UnicodeString; var Bounds: TRect; DrawFormat: Cardinal);

begin
  Bounds.Right := Bounds.Left + 1;
  Bounds.Bottom := Bounds.Top + 1;

  Windows.DrawTextW(DC, PWideChar(S), Length(S), Bounds, DrawFormat or DT_CALCRECT)
end;

procedure FillDragRectangles(DragWidth, DragHeight, DeltaX, DeltaY: Integer; var RClip, RScroll, RSamp1, RSamp2, RDraw1,
  RDraw2: TRect);

begin
  
  RClip := Rect(0, 0, DragWidth, DragHeight);
  if DeltaX > 0 then
  begin
    
    if DeltaY = 0 then
    begin
      
      RScroll := Rect(0, 0, DragWidth - DeltaX, DragHeight);
      RSamp1 := Rect(0, 0, DeltaX, DragHeight);
      RDraw1 := Rect(DragWidth - DeltaX, 0, DeltaX, DragHeight);
    end
    else
      if DeltaY < 0 then
      begin
        
        RScroll := Rect(0, -DeltaY, DragWidth - DeltaX, DragHeight);
        RSamp1 := Rect(0, 0, DeltaX, DragHeight);
        RSamp2 := Rect(DeltaX, DragHeight + DeltaY, DragWidth - DeltaX, -DeltaY);
        RDraw1 := Rect(0, 0, DragWidth - DeltaX, -DeltaY);
        RDraw2 := Rect(DragWidth - DeltaX, 0, DeltaX, DragHeight);
      end
      else
      begin
        
        RScroll := Rect(0, 0, DragWidth - DeltaX, DragHeight - DeltaY);
        RSamp1 := Rect(0, 0, DeltaX, DragHeight);
        RSamp2 := Rect(DeltaX, 0, DragWidth - DeltaX, DeltaY);
        RDraw1 := Rect(0, DragHeight - DeltaY, DragWidth - DeltaX, DeltaY);
        RDraw2 := Rect(DragWidth - DeltaX, 0, DeltaX, DragHeight);
      end;
  end
  else
    if DeltaX = 0 then
    begin
      
      if DeltaY < 0 then
      begin
        
        RScroll := Rect(0, -DeltaY, DragWidth, DragHeight);
        RSamp2 := Rect(0, DragHeight + DeltaY, DragWidth, -DeltaY);
        RDraw2 := Rect(0, 0, DragWidth, -DeltaY);
      end
      else
      begin
        
        RScroll := Rect(0, 0, DragWidth, DragHeight - DeltaY);
        RSamp2 := Rect(0, 0, DragWidth, DeltaY);
        RDraw2 := Rect(0, DragHeight - DeltaY, DragWidth, DeltaY);
      end;
    end
    else
    begin
      
      if DeltaY > 0 then
      begin
        
        RScroll := Rect(-DeltaX, 0, DragWidth, DragHeight);
        RSamp1 := Rect(0, 0, DragWidth + DeltaX, DeltaY);
        RSamp2 := Rect(DragWidth + DeltaX, 0, -DeltaX, DragHeight);
        RDraw1 := Rect(0, 0, -DeltaX, DragHeight);
        RDraw2 := Rect(-DeltaX, DragHeight - DeltaY, DragWidth + DeltaX, DeltaY);
      end
      else
        if DeltaY = 0 then
        begin
          
          RScroll := Rect(-DeltaX, 0, DragWidth, DragHeight);
          RSamp1 := Rect(DragWidth + DeltaX, 0, -DeltaX, DragHeight);
          RDraw1 := Rect(0, 0, -DeltaX, DragHeight);
        end
        else
        begin
          
          RScroll := Rect(-DeltaX, -DeltaY, DragWidth, DragHeight);
          RSamp1 := Rect(0, DragHeight + DeltaY, DragWidth + DeltaX, -DeltaY);
          RSamp2 := Rect(DragWidth + DeltaX, 0, -DeltaX, DragHeight);
          RDraw1 := Rect(0, 0, -DeltaX, DragHeight);
          RDraw2 := Rect(-DeltaX, 0, DragWidth + DeltaX, -DeltaY);
        end;
    end;
end;

procedure AlphaBlendLineConstant(Source, Destination: Pointer; Count: Integer; ConstantAlpha, Bias: Integer);

{$ifdef CPUX64}

asm
        
        MOVD        XMM3, R9D  
        PUNPCKLWD   XMM3, XMM3
        PUNPCKLDQ   XMM3, XMM3
        
        MOVD        XMM5, [Bias]
        PUNPCKLWD   XMM5, XMM5
        PUNPCKLDQ   XMM5, XMM5
        
        MOV         R10D, 128
        MOVD        XMM4, R10D
        PUNPCKLWD   XMM4, XMM4
        PUNPCKLDQ   XMM4, XMM4

@1:     
        
        MOVD        XMM1, DWORD PTR [RCX]   
        MOVD        XMM2, DWORD PTR [RDX]   
        PXOR        XMM0, XMM0    
        PUNPCKLBW   XMM0, XMM1    
        PSRLW       XMM0, 8       
        PXOR        XMM1, XMM1    
        PUNPCKLBW   XMM1, XMM2    
        MOVQ        XMM2, XMM1    
        PSRLW       XMM1, 8       
        
        PSUBW       XMM0, XMM1    
        PMULLW      XMM0, XMM3    
        PADDW       XMM0, XMM2    
        PSRLW       XMM0, 8       
        
        PSUBW     XMM0, XMM4
        PADDSW    XMM0, XMM5
        PADDW     XMM0, XMM4
        PACKUSWB  XMM0, XMM0      
        MOVD      DWORD PTR [RDX], XMM0     
@3:
        ADD       RCX, 4
        ADD       RDX, 4
        DEC       R8D
        JNZ       @1
end;
{$else}

asm
        PUSH    ESI                    
        PUSH    EDI

        MOV     ESI, EAX               
        MOV     EDI, EDX               
        
        MOV     EAX, [ConstantAlpha]
        DB      $0F, $6E, $F0          
        DB      $0F, $61, $F6          
        DB      $0F, $62, $F6          
        
        MOV     EAX, [Bias]
        DB      $0F, $6E, $E8          
        DB      $0F, $61, $ED          
        DB      $0F, $62, $ED          
        
        MOV     EAX, 128
        DB      $0F, $6E, $E0          
        DB      $0F, $61, $E4          
        DB      $0F, $62, $E4          

@1:     
        
        DB      $0F, $EF, $C0          
        DB      $0F, $60, $06          
        DB      $0F, $71, $D0, $08     
        DB      $0F, $EF, $C9          
        DB      $0F, $60, $0F          
        DB      $0F, $6F, $D1          
        DB      $0F, $71, $D1, $08     
        
        DB      $0F, $F9, $C1          
        DB      $0F, $D5, $C6          
        DB      $0F, $FD, $C2          
        DB      $0F, $71, $D0, $08     
        
        DB      $0F, $F9, $C4          
        DB      $0F, $ED, $C5          
        DB      $0F, $FD, $C4          
        DB      $0F, $67, $C0          
        DB      $0F, $7E, $07          
@3:
        ADD     ESI, 4
        ADD     EDI, 4
        DEC     ECX
        JNZ     @1
        POP     EDI
        POP     ESI
end;
{$endif CPUX64}

procedure AlphaBlendLinePerPixel(Source, Destination: Pointer; Count, Bias: Integer);

{$ifdef CPUX64}

asm
        
        MOVD        XMM5, R9D   
        PUNPCKLWD   XMM5, XMM5
        PUNPCKLDQ   XMM5, XMM5
        
        MOV         R10D, 128
        MOVD        XMM4, R10D
        PUNPCKLWD   XMM4, XMM4
        PUNPCKLDQ   XMM4, XMM4

@1:     
        
        MOVD        XMM1, DWORD PTR [RCX]   
        MOVD        XMM2, DWORD PTR [RDX]   
        PXOR        XMM0, XMM0    
        PUNPCKLBW   XMM0, XMM1    
        PSRLW       XMM0, 8       
        PXOR        XMM1, XMM1    
        PUNPCKLBW   XMM1, XMM2    
        MOVQ        XMM2, XMM1    
        PSRLW       XMM1, 8       
        
        MOVQ        XMM3, XMM0
        PUNPCKHWD   XMM3, XMM3
        PUNPCKHDQ   XMM3, XMM3
        
        PSUBW       XMM0, XMM1    
        PMULLW      XMM0, XMM3    
        PADDW       XMM0, XMM2    
        PSRLW       XMM0, 8       
        
        PSUBW       XMM0, XMM4
        PADDSW      XMM0, XMM5
        PADDW       XMM0, XMM4
        PACKUSWB    XMM0, XMM0    
        MOVD        DWORD PTR [RDX], XMM0   
@3:
        ADD         RCX, 4
        ADD         RDX, 4
        DEC         R8D
        JNZ         @1
end;
{$else}

asm
        PUSH    ESI                    
        PUSH    EDI

        MOV     ESI, EAX               
        MOV     EDI, EDX               
        
        MOV     EAX, [Bias]
        DB      $0F, $6E, $E8          
        DB      $0F, $61, $ED          
        DB      $0F, $62, $ED          
        
        MOV     EAX, 128
        DB      $0F, $6E, $E0          
        DB      $0F, $61, $E4          
        DB      $0F, $62, $E4          

@1:     
        
        DB      $0F, $EF, $C0          
        DB      $0F, $60, $06          
        DB      $0F, $71, $D0, $08     
        DB      $0F, $EF, $C9          
        DB      $0F, $60, $0F          
        DB      $0F, $6F, $D1          
        DB      $0F, $71, $D1, $08     
        
        DB      $0F, $6F, $F0          
        DB      $0F, $69, $F6          
        DB      $0F, $6A, $F6          
        
        DB      $0F, $F9, $C1          
        DB      $0F, $D5, $C6          
        DB      $0F, $FD, $C2          
        DB      $0F, $71, $D0, $08     
        
        DB      $0F, $F9, $C4          
        DB      $0F, $ED, $C5          
        DB      $0F, $FD, $C4          
        DB      $0F, $67, $C0          
        DB      $0F, $7E, $07          
@3:
        ADD     ESI, 4
        ADD     EDI, 4
        DEC     ECX
        JNZ     @1
        POP     EDI
        POP     ESI
end;
{$endif CPUX64}

procedure AlphaBlendLineMaster(Source, Destination: Pointer; Count: Integer; ConstantAlpha, Bias: Integer);

{$ifdef CPUX64}

asm
        .SAVENV XMM6
        
        MOVD        XMM3, R9D    
        PUNPCKLWD   XMM3, XMM3
        PUNPCKLDQ   XMM3, XMM3
        
        MOV         R10D, [Bias]
        MOVD        XMM5, R10D
        PUNPCKLWD   XMM5, XMM5
        PUNPCKLDQ   XMM5, XMM5
        
        MOV         R10D, 128
        MOVD        XMM4, R10D
        PUNPCKLWD   XMM4, XMM4
        PUNPCKLDQ   XMM4, XMM4

@1:     
        
        MOVD        XMM1, DWORD PTR [RCX]   
        MOVD        XMM2, DWORD PTR [RDX]   
        PXOR        XMM0, XMM0    
        PUNPCKLBW   XMM0, XMM1     
        PSRLW       XMM0, 8       
        PXOR        XMM1, XMM1    
        PUNPCKLBW   XMM1, XMM2     
        MOVQ        XMM2, XMM1    
        PSRLW       XMM1, 8       
        
        MOVQ        XMM6, XMM0
        PUNPCKHWD   XMM6, XMM6
        PUNPCKHDQ   XMM6, XMM6
        PMULLW      XMM6, XMM3    
        PSRLW       XMM6, 8       
        
        PSUBW       XMM0, XMM1    
        PMULLW      XMM0, XMM6    
        PADDW       XMM0, XMM2    
        PSRLW       XMM0, 8       
        
        PSUBW       XMM0, XMM4
        PADDSW      XMM0, XMM5
        PADDW       XMM0, XMM4
        PACKUSWB    XMM0, XMM0    
        MOVD        DWORD PTR [RDX], XMM0   
@3:
        ADD         RCX, 4
        ADD         RDX, 4
        DEC         R8D
        JNZ         @1
end;
{$else}

asm
        PUSH    ESI                    
        PUSH    EDI

        MOV     ESI, EAX               
        MOV     EDI, EDX               
        
        MOV     EAX, [ConstantAlpha]
        DB      $0F, $6E, $F0          
        DB      $0F, $61, $F6          
        DB      $0F, $62, $F6          
        
        MOV     EAX, [Bias]
        DB      $0F, $6E, $E8          
        DB      $0F, $61, $ED          
        DB      $0F, $62, $ED          
        
        MOV     EAX, 128
        DB      $0F, $6E, $E0          
        DB      $0F, $61, $E4          
        DB      $0F, $62, $E4          

@1:     
        
        DB      $0F, $EF, $C0          
        DB      $0F, $60, $06          
        DB      $0F, $71, $D0, $08     
        DB      $0F, $EF, $C9          
        DB      $0F, $60, $0F          
        DB      $0F, $6F, $D1          
        DB      $0F, $71, $D1, $08     
        
        DB      $0F, $6F, $F8          
        DB      $0F, $69, $FF          
        DB      $0F, $6A, $FF          
        DB      $0F, $D5, $FE          
        DB      $0F, $71, $D7, $08     
        
        DB      $0F, $F9, $C1          
        DB      $0F, $D5, $C7          
        DB      $0F, $FD, $C2          
        DB      $0F, $71, $D0, $08     
        
        DB      $0F, $F9, $C4          
        DB      $0F, $ED, $C5          
        DB      $0F, $FD, $C4          
        DB      $0F, $67, $C0          
        DB      $0F, $7E, $07          
@3:
        ADD     ESI, 4
        ADD     EDI, 4
        DEC     ECX
        JNZ     @1
        POP     EDI
        POP     ESI
end;
{$endif CPUX64}

procedure AlphaBlendLineMasterAndColor(Destination: Pointer; Count: Integer; ConstantAlpha, Color: Integer);

{$ifdef CPUX64}

asm
        
        MOVD        XMM3, R8D   
        PUNPCKLWD   XMM3, XMM3
        PUNPCKLDQ   XMM3, XMM3
        
        MOV         R10D, $100
        MOVD        XMM2, R10D
        PUNPCKLWD   XMM2, XMM2
        PUNPCKLDQ   XMM2, XMM2
        PSUBW       XMM2, XMM3             
        
        BSWAP       R9D  
        ROR         R9D, 8
        MOVD        XMM1, R9D              
        PXOR        XMM4, XMM4
        PUNPCKLBW   XMM1, XMM4
        PMULLW      XMM1, XMM3             

@1:     
        MOVD        XMM0, DWORD PTR [RCX]
        PUNPCKLBW   XMM0, XMM4

        PMULLW      XMM0, XMM2             
        PADDW       XMM0, XMM1
        PSRLW       XMM0, 8                

        PACKUSWB    XMM0, XMM0             
        MOVD        DWORD PTR [RCX], XMM0            

        ADD         RCX, 4
        DEC         EDX
        JNZ         @1
end;
{$else}

asm
        
        DB      $0F, $6E, $D9          
        DB      $0F, $61, $DB          
        DB      $0F, $62, $DB          
        
        MOV     ECX, $100
        DB      $0F, $6E, $D1          
        DB      $0F, $61, $D2          
        DB      $0F, $62, $D2          
        DB      $0F, $F9, $D3          
        
        MOV     ECX, [Color]
        BSWAP   ECX
        ROR     ECX, 8
        DB      $0F, $6E, $C9          
        DB      $0F, $EF, $E4          
        DB      $0F, $60, $CC          
        DB      $0F, $D5, $CB          

@1:     
        DB      $0F, $6E, $00          
        DB      $0F, $60, $C4          

        DB      $0F, $D5, $C2          
        DB      $0F, $FD, $C1          
        DB      $0F, $71, $D0, $08     

        DB      $0F, $67, $C0          
        DB      $0F, $7E, $00          

        ADD     EAX, 4
        DEC     EDX
        JNZ     @1
end;
{$endif CPUX64}

procedure EMMS;

{$ifdef CPUX64}
  inline;
begin
end;
{$else}
asm
        DB      $0F, $77               
end;
{$endif CPUX64}

function GetBitmapBitsFromDeviceContext(DC: HDC; var Width, Height: Integer): Pointer;

var
  Bitmap: HBITMAP;
  DIB: TDIBSection;

begin
  Result := nil;
  Width := 0;
  Height := 0;

  Bitmap := GetCurrentObject(DC, OBJ_BITMAP);
  if Bitmap <> 0 then
  begin
    if GetObject(Bitmap, SizeOf(DIB), @DIB) = SizeOf(DIB) then
    begin
      Assert(DIB.dsBm.bmPlanes * DIB.dsBm.bmBitsPixel = 32, 'Alpha blending error: bitmap must use 32 bpp.');
      Result := DIB.dsBm.bmBits;
      Width := DIB.dsBmih.biWidth;
      Height := DIB.dsBmih.biHeight;
    end;
  end;
  Assert(Result <> nil, 'Alpha blending DC error: no bitmap available.');
end;

function CalculateScanline(Bits: Pointer; Width, Height, Row: Integer): Pointer;

begin
  if Height > 0 then  
    Row := Height - Row - 1;
  
  Result := PAnsiChar(Bits) + Row * ((Width * 32 + 31) and not 31) div 8;
end;

procedure AlphaBlend(Source, Destination: HDC; R: TRect; Target: TPoint; Mode: TBlendMode; ConstantAlpha, Bias: Integer);

var
  Y: Integer;
  SourceRun,
  TargetRun: PByte;

  SourceBits,
  DestBits: Pointer;
  SourceWidth,
  SourceHeight,
  DestWidth,
  DestHeight: Integer;

begin
  if not IsRectEmpty(R) then
  begin
    
    case Mode of
      bmConstantAlpha:
        begin
          
          SourceBits := GetBitmapBitsFromDeviceContext(Source, SourceWidth, SourceHeight);
          DestBits := GetBitmapBitsFromDeviceContext(Destination, DestWidth, DestHeight);
          if Assigned(SourceBits) and Assigned(DestBits) then
          begin
            for Y := 0 to R.Bottom - R.Top - 1 do
            begin
              SourceRun := CalculateScanline(SourceBits, SourceWidth, SourceHeight, Y + R.Top);
              Inc(SourceRun, 4 * R.Left);
              TargetRun := CalculateScanline(DestBits, DestWidth, DestHeight, Y + Target.Y);
              Inc(TargetRun, 4 * Target.X);
              AlphaBlendLineConstant(SourceRun, TargetRun, R.Right - R.Left, ConstantAlpha, Bias);
            end;
          end;
          EMMS;
        end;
      bmPerPixelAlpha:
        begin
          SourceBits := GetBitmapBitsFromDeviceContext(Source, SourceWidth, SourceHeight);
          DestBits := GetBitmapBitsFromDeviceContext(Destination, DestWidth, DestHeight);
          if Assigned(SourceBits) and Assigned(DestBits) then
          begin
            for Y := 0 to R.Bottom - R.Top - 1 do
            begin
              SourceRun := CalculateScanline(SourceBits, SourceWidth, SourceHeight, Y + R.Top);
              Inc(SourceRun, 4 * R.Left);
              TargetRun := CalculateScanline(DestBits, DestWidth, DestHeight, Y + Target.Y);
              Inc(TargetRun, 4 * Target.X);
              AlphaBlendLinePerPixel(SourceRun, TargetRun, R.Right - R.Left, Bias);
            end;
          end;
          EMMS;
        end;
      bmMasterAlpha:
        begin
          SourceBits := GetBitmapBitsFromDeviceContext(Source, SourceWidth, SourceHeight);
          DestBits := GetBitmapBitsFromDeviceContext(Destination, DestWidth, DestHeight);
          if Assigned(SourceBits) and Assigned(DestBits) then
          begin
            for Y := 0 to R.Bottom - R.Top - 1 do
            begin
              SourceRun := CalculateScanline(SourceBits, SourceWidth, SourceHeight, Y + R.Top);
              Inc(SourceRun, 4 * Target.X);
              TargetRun := CalculateScanline(DestBits, DestWidth, DestHeight, Y + Target.Y);
              AlphaBlendLineMaster(SourceRun, TargetRun, R.Right - R.Left, ConstantAlpha, Bias);
            end;
          end;
          EMMS;
        end;
      bmConstantAlphaAndColor:
        begin
          
          DestBits := GetBitmapBitsFromDeviceContext(Destination, DestWidth, DestHeight);
          if Assigned(DestBits) then
          begin
            for Y := 0 to R.Bottom - R.Top - 1 do
            begin
              TargetRun := CalculateScanline(DestBits, DestWidth, DestHeight, Y + R.Top);
              Inc(TargetRun, 4 * R.Left);
              AlphaBlendLineMasterAndColor(TargetRun, R.Right - R.Left, ConstantAlpha, Bias);
            end;
          end;
          EMMS;
        end;
    end;
  end;
end;

function GetRGBColor(Value: TColor): DWORD;

begin
  Result := ColorToRGB(Value);
  case Result of
    clNone:
      Result := CLR_NONE;
    clDefault:
      Result := CLR_DEFAULT;
  end;
end;

const
  Grays: array[0..3] of TColor = (clWhite, clSilver, clGray, clBlack);
  SysGrays: array[0..3] of TColor = (clWindow, clBtnFace, clBtnShadow, clBtnText);

procedure ConvertImageList(IL: TImageList; const ImageName: string; ColorRemapping: Boolean = True);

var
  Images,
  OneImage: TBitmap;
  I: Integer;
  MaskColor: TColor;
  Source,
  Dest: TRect;

begin
  Watcher.Enter;
  try
    
    Images := TBitmap.Create;
    OneImage := TBitmap.Create;
    if ColorRemapping then
      Images.Handle := CreateMappedRes(FindClassHInstance(TBaseVirtualTree), PChar(ImageName), Grays, SysGrays)
    else
      Images.Handle := LoadBitmap(FindClassHInstance(TBaseVirtualTree), PChar(ImageName));

    try
      Assert(Images.Height > 0, 'Internal image "' + ImageName + '" is missing or corrupt.');
      if Images.Height = 0 then
        Exit;
      
      IL.Clear;
      IL.Height := Images.Height;
      IL.Width := Images.Height;
      OneImage.Width := IL.Width;
      OneImage.Height := IL.Height;
      MaskColor := Images.Canvas.Pixels[0, 0]; 
      Dest := Rect(0, 0, IL.Width, IL.Height);
      for I := 0 to (Images.Width div Images.Height) - 1 do
      begin
        Source := Rect(I * IL.Width, 0, (I + 1) * IL.Width, IL.Height);
        OneImage.Canvas.CopyRect(Dest, Images.Canvas, Source);
        IL.AddMasked(OneImage, MaskColor);
      end;
    finally
      Images.Free;
      OneImage.Free;
    end;
  finally
    Watcher.Leave;
  end;
end;

procedure CreateSystemImageSet(var IL: TImageList; Flags: Cardinal; Flat: Boolean);

const
  MaskColor: TColor = clRed;

var
  BM: TBitmap;

  procedure AddNodeImages(IL: TImageList);

  var
    I: Integer;
    OffsetX,
    OffsetY: Integer;

  begin
    
    OffsetX := (IL.Width - DarkCheckImages.Width) div 2;
    OffsetY := (IL.Height - DarkCheckImages.Height) div 2;
    for I := 21 to 24 do
    begin
      BM.Canvas.Brush.Color := MaskColor;
      BM.Canvas.FillRect(Rect(0, 0, BM.Width, BM.Height));
      if Flat then
        FlatImages.Draw(BM.Canvas, OffsetX, OffsetY, I)
      else
        DarkCheckImages.Draw(BM.Canvas, OffsetX, OffsetY, I);
      IL.AddMasked(BM, MaskColor);
    end;
  end;

  procedure AddSystemImage(IL: TImageList; Index: Integer);

  var
    ButtonState: Cardinal;
    ButtonType: Cardinal;

  begin
    BM.Canvas.Brush.Color := MaskColor;
    BM.Canvas.FillRect(Rect(0, 0, BM.Width, BM.Height));
    if Index < 8 then
      ButtonType := DFCS_BUTTONRADIO
    else
      ButtonType := DFCS_BUTTONCHECK;
    if Index >= 16 then
      ButtonType := ButtonType or DFCS_BUTTON3STATE;

    case Index mod 4 of
      0:
        ButtonState := 0;
      1:
        ButtonState := DFCS_HOT;
      2:
        ButtonState := DFCS_PUSHED;
      else
        ButtonState := DFCS_INACTIVE;
    end;
    if Index in [4..7, 12..19] then
      ButtonState := ButtonState or DFCS_CHECKED;
    if Flat then
      ButtonState := ButtonState or DFCS_FLAT;
    DrawFrameControl(BM.Canvas.Handle, Rect(1, 2, BM.Width - 2, BM.Height - 1), DFC_BUTTON, ButtonType or ButtonState);
    IL.AddMasked(BM, MaskColor);
  end;

var
  I, Width, Height: Integer;

begin
  Width := GetSystemMetrics(SM_CXMENUCHECK) + 3;
  Height := GetSystemMetrics(SM_CYMENUCHECK) + 3;
  IL := TImageList.CreateSize(Width, Height);
  with IL do
    Handle := ImageList_Create(Width, Height, Flags, 0, AllocBy);
  IL.Masked := True;
  IL.BkColor :=clWhite;
  
  BM := TBitmap.Create;
  try
    
    BM.Width := IL.Width;
    BM.Height := IL.Height;
    BM.Canvas.Brush.Color := MaskColor;
    BM.Canvas.Brush.Style := bsSolid;
    BM.Canvas.FillRect(Rect(0, 0, BM.Width, BM.Height));
    IL.AddMasked(BM, MaskColor);
    
    for I := 0 to 19 do
      AddSystemImage(IL, I);
    
    AddNodeImages(IL);

  finally
    BM.Free;
  end;
end;

function HasMMX: Boolean;

{$ifdef CPUX64}
begin
  
  Result := True;
end;
{$else}
asm
        PUSH    EBX
        XOR     EAX, EAX     
        PUSHFD               
        POP     EDX
        MOV     ECX, EDX
        XOR     EDX, $200000
        PUSH    EDX
        POPFD
        PUSHFD
        POP     EDX
        XOR     ECX, EDX
        JZ      @1           
        PUSH    EDX
        POPFD

        MOV     EAX, 1
        DW      $A20F        
        MOV     EBX, EAX     
        XOR     EAX, EAX     
        CMP     EBX, $50
        JB      @1           
        TEST    EDX, $800000
        JZ      @1           
        INC     EAX          
@1:
        POP     EBX
end;
{$endif CPUX64}

procedure PrtStretchDrawDIB(Canvas: TCanvas; DestRect: TRect; ABitmap: TBitmap);

var
  Header,
  Bits: Pointer;
  HeaderSize,
  BitsSize: Cardinal;

begin
  GetDIBSizes(ABitmap.Handle, HeaderSize, BitsSize);

  GetMem(Header, HeaderSize);
  GetMem(Bits, BitsSize);
  try
    GetDIB(ABitmap.Handle, ABitmap.Palette, Header^, Bits^);
    StretchDIBits(Canvas.Handle, DestRect.Left, DestRect.Top, DestRect.Right - DestRect.Left, DestRect.Bottom -
      DestRect.Top, 0, 0, ABitmap.Width, ABitmap.Height, Bits, TBitmapInfo(Header^), DIB_RGB_COLORS, SRCCOPY);
  finally
    FreeMem(Header);
    FreeMem(Bits);
  end;
end;

procedure ClipCanvas(Canvas: TCanvas; ClipRect: TRect; VisibleRegion: HRGN = 0);

var
  ClipRegion: HRGN;

begin
  
  LPtoDP(Canvas.Handle, ClipRect, 2);
  ClipRegion := CreateRectRgnIndirect(ClipRect);
  if VisibleRegion <> 0 then
    CombineRgn(ClipRegion, ClipRegion, VisibleRegion, RGN_AND);
  SelectClipRgn(Canvas.Handle, ClipRegion);
  DeleteObject(ClipRegion);
end;

procedure SetCanvasOrigin(Canvas: TCanvas; X, Y: Integer);

var
  P: TPoint;

begin
  
  SetWindowOrgEx(Canvas.Handle, 0, 0, nil);
  
  P := Point(X, Y);
  LPtoDP(Canvas.Handle, P, 1);
  
  SetWindowOrgEx(Canvas.Handle, P.X, P.Y, nil);
end;

procedure SetBrushOrigin(Canvas: TCanvas; X, Y: Integer);

var
  P: TPoint;

begin
  P := Point(X, Y);
  LPtoDP(Canvas.Handle, P, 1);
  SetBrushOrgEx(Canvas.Handle, P.X, P.Y, nil);
end;

procedure InitializeGlobalStructures;

var
  Flags: Cardinal;

begin
  Initialized := True;
  
  MMXAvailable := HasMMX;
  IsWinVistaOrAbove := (Win32MajorVersion >= 6);
  
  NeedToUnitialize := not IsLibrary and Succeeded(OleInitialize(nil));
  
  CF_VTREFERENCE := RegisterClipboardFormat(CFSTR_VTREFERENCE);
  
  Flags := ILC_COLOR32 or ILC_MASK;
  LightCheckImages := TImageList.Create(nil);
  with LightCheckImages do
    Handle := ImageList_Create(16, 16, Flags, 0, AllocBy);
  ConvertImageList(LightCheckImages, 'VT_CHECK_LIGHT');

  DarkCheckImages := TImageList.CreateSize(16, 16);
  with DarkCheckImages do
    Handle := ImageList_Create(16, 16, Flags, 0, AllocBy);
  ConvertImageList(DarkCheckImages, 'VT_CHECK_DARK');

  LightTickImages := TImageList.CreateSize(16, 16);
  with LightTickImages do
    Handle := ImageList_Create(16, 16, Flags, 0, AllocBy);
  ConvertImageList(LightTickImages, 'VT_TICK_LIGHT');

  DarkTickImages := TImageList.CreateSize(16, 16);
  with DarkTickImages do
    Handle := ImageList_Create(16, 16, Flags, 0, AllocBy);
  ConvertImageList(DarkTickImages, 'VT_TICK_DARK');

  FlatImages := TImageList.CreateSize(16, 16);
  with FlatImages do
    Handle := ImageList_Create(16, 16, Flags, 0, AllocBy);
  ConvertImageList(FlatImages, 'VT_FLAT');

  XPImages := TImageList.CreateSize(16, 16);
  with XPImages do
    Handle := ImageList_Create(16, 16, Flags, 0, AllocBy);
  ConvertImageList(XPImages, 'VT_XP', False);

  UtilityImages := TImageList.CreateSize(UtilityImageSize, UtilityImageSize);
  with UtilityImages do
    Handle := ImageList_Create(UtilityImageSize, UtilityImageSize, Flags, 0, AllocBy);
  ConvertImageList(UtilityImages, 'VT_UTILITIES');

  CreateSystemImageSet(SystemCheckImages, Flags, False);
  CreateSystemImageSet(SystemFlatCheckImages, Flags, True);
  
  Screen.Cursors[crHeaderSplit] := LoadCursor(HInstance, 'VT_HEADERSPLIT');
  Screen.Cursors[crVertSplit] := LoadCursor(HInstance, 'VT_VERTSPLIT');
  
  CF_VIRTUALTREE := RegisterVTClipboardFormat(CFSTR_VIRTUALTREE, TBaseVirtualTree, 50, TYMED_HGLOBAL );
  
  CF_HTML := RegisterVTClipboardFormat(CFSTR_HTML, TCustomVirtualStringTree, 80);
  CF_VRTFNOOBJS := RegisterVTClipboardFormat(CFSTR_RTFNOOBJS, TCustomVirtualStringTree, 84);
  CF_VRTF := RegisterVTClipboardFormat(CFSTR_RTF, TCustomVirtualStringTree, 85);
  CF_CSV := RegisterVTClipboardFormat(CFSTR_CSV, TCustomVirtualStringTree, 90);
  
  RegisterVTClipboardFormat(CF_TEXT, TCustomVirtualStringTree, 100);
  RegisterVTClipboardFormat(CF_UNICODETEXT, TCustomVirtualStringTree, 95);
  {$if CompilerVersion >= 23}
  TCustomStyleEngine.RegisterStyleHook(TBaseVirtualTree, TVclStyleScrollBarsHook);
  {$ifend}
end;

procedure FinalizeGlobalStructures;

var
  HintWasEnabled: Boolean;

begin
  LightCheckImages.Free;
  LightCheckImages := nil;
  DarkCheckImages.Free;
  DarkCheckImages := nil;
  LightTickImages.Free;
  LightTickImages := nil;
  DarkTickImages.Free;
  DarkTickImages := nil;
  FlatImages.Free;
  FlatImages := nil;
  XPImages.Free;
  XPImages := nil;
  UtilityImages.Free;
  UtilityImages := nil;
  SystemCheckImages.Free;
  SystemCheckImages := nil;
  SystemFlatCheckImages.Free;
  SystemFlatCheckImages := nil;

  if NeedToUnitialize then
    OleUninitialize;
  
  if ModuleIsPackage then
  begin
    HintWasEnabled := Application.ShowHint;
    Application.ShowHint := False;
    if HintWasEnabled then
      Application.ShowHint := True;
  end;
end;

constructor TCriticalSection.Create;

begin
  inherited Create;
  InitializeCriticalSection(FSection);
end;

destructor TCriticalSection.Destroy;

begin
  DeleteCriticalSection(FSection);

  inherited Destroy;
end;

procedure TCriticalSection.Enter;

begin
  EnterCriticalSection(FSection);
end;

procedure TCriticalSection.Leave;

begin
  LeaveCriticalSection(FSection);
end;

procedure AddThreadReference;
begin
  if not Assigned(WorkerThread) then
  begin
    
    WorkEvent := CreateEvent(nil, False, False, nil);
    if WorkEvent = 0 then
      RaiseLastOSError;
    
    WorkerThread := TWorkerThread.Create(False);
  end;
  Inc(WorkerThread.FRefCount);
end;

procedure ReleaseThreadReference(Tree: TBaseVirtualTree);

begin
  if Assigned(WorkerThread) then
  begin
    Dec(WorkerThread.FRefCount);
    
    Tree.InterruptValidation;

    if WorkerThread.FRefCount = 0 then
    begin
      with WorkerThread do
      begin
        Terminate;
        SetEvent(WorkEvent);
      end;
      FreeAndNil(WorkerThread);
      CloseHandle(WorkEvent);
    end;
  end;
end;

constructor TWorkerThread.Create(CreateSuspended: Boolean);

begin
  inherited Create(CreateSuspended);
  FWaiterList := TThreadList.Create;
end;

destructor TWorkerThread.Destroy;

begin
  
  inherited;

  FWaiterList.Free;
end;

procedure TWorkerThread.CancelValidation(Tree: TBaseVirtualTree);

var
  Msg: TMsg;

begin
  
  while FCurrentTree = Tree do
  begin
    if Tree.HandleAllocated and PeekMessage(Msg, Tree.Handle, WM_CHANGESTATE, WM_CHANGESTATE, PM_REMOVE) then
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
    CheckSynchronize();
  end;
end;

procedure TWorkerThread.ChangeTreeStates(EnterStates, LeaveStates: TChangeStates);

begin
  if Assigned(FCurrentTree) and (FCurrentTree.HandleAllocated) then
    SendMessage(FCurrentTree.Handle, WM_CHANGESTATE, Byte(EnterStates), Byte(LeaveStates));
end;

procedure TWorkerThread.Execute;

var
  EnterStates,
  LeaveStates: TChangeStates;

begin
  {$if CompilerVersion >= 21} TThread.NameThreadForDebugging('VirtualTrees.TWorkerThread');{$ifend}
  while not Terminated do
  begin
    WaitForSingleObject(WorkEvent, INFINITE);
    if not Terminated then
    begin
      
      with FWaiterList.LockList do
      try
        if Count > 0 then
        begin
          FCurrentTree := Items[0];
          
          Delete(0);
          
          if Count > 0 then
            SetEvent(WorkEvent);
        end
        else
          FCurrentTree := nil;
      finally
        FWaiterList.UnlockList;
      end;
      
      if Assigned(FCurrentTree) then
      begin
        try
          ChangeTreeStates([csValidating], [csUseCache]);
          EnterStates := [];
          if not (tsStopValidation in FCurrentTree.FStates) and FCurrentTree.DoValidateCache then
            EnterStates := [csUseCache];

        finally
          LeaveStates := [csValidating, csStopValidation];
          if csUseCache in EnterStates then
            Include(LeaveStates, csValidationNeeded);
          ChangeTreeStates(EnterStates, LeaveStates);
          Synchronize(FCurrentTree.UpdateEditBounds);
          FCurrentTree := nil;
        end;
      end;
    end;
  end;
end;

procedure TWorkerThread.AddTree(Tree: TBaseVirtualTree);

begin
  Assert(Assigned(Tree), 'Tree must not be nil.');
  
  Tree.DoStateChange([], [tsStopValidation]);
  with FWaiterList.LockList do
  try
    if IndexOf(Tree) = -1 then
      Add(Tree);
  finally
    FWaiterList.UnlockList;
  end;
end;

procedure TWorkerThread.RemoveTree(Tree: TBaseVirtualTree);

begin
  Assert(Assigned(Tree), 'Tree must not be nil.');

  with FWaiterList.LockList do
  try
    Remove(Tree);
  finally
    FWaiterList.UnlockList; 
  end;
  CancelValidation(Tree);
end;

const
  AllocIncrement = 2 shl 11;  

destructor TBufferedAnsiString.Destroy;

begin
  FreeMem(FStart);
  inherited;
end;

function TBufferedAnsiString.GetAsString: RawBytestring;

begin
  SetString(Result, FStart, FPosition - FStart);
end;

procedure TBufferedAnsiString.Add(const S: RawByteString);

var
  NewLen,
  LastOffset,
  Len: NativeInt;

begin
  Len := Length(S);
  
  if FEnd - FPosition <= Len then
  begin
    
    NewLen := FEnd - FStart + (Len + AllocIncrement - 1) and not (AllocIncrement - 1);
    
    LastOffset := FPosition - FStart;
    ReallocMem(FStart, NewLen);
    FPosition := FStart + LastOffset;
    FEnd := FStart + NewLen;
  end;
  Move(PAnsiChar(S)^, FPosition^, Len);
  Inc(FPosition, Len);
end;

procedure TBufferedAnsiString.AddNewLine;

var
  NewLen,
  LastOffset: NativeInt;

begin
  
  if FEnd - FPosition <= 2 then
  begin
    
    NewLen := FEnd - FStart + (2 + AllocIncrement - 1) and not (AllocIncrement - 1);
    
    LastOffset := FPosition - FStart;
    ReallocMem(FStart, NewLen);
    FPosition := FStart + LastOffset;
    FEnd := FStart + NewLen;
  end;
  FPosition^ := #13;
  Inc(FPosition);
  FPosition^ := #10;
  Inc(FPosition);
end;

destructor TWideBufferedString.Destroy;

begin
  FreeMem(FStart);
  inherited;
end;

function TWideBufferedString.GetAsString: UnicodeString;

begin
  SetString(Result, FStart, FPosition - FStart);
end;

procedure TWideBufferedString.Add(const S: UnicodeString);

var
  NewLen,
  LastOffset,
  Len: Integer;

begin
  Len := Length(S);
  
  if FEnd - FPosition <= Len then
  begin
    
    NewLen := FEnd - FStart + (Len + AllocIncrement - 1) and not (AllocIncrement - 1);
    
    LastOffset := FPosition - FStart;
    ReallocMem(FStart, 2 * NewLen);
    FPosition := FStart + LastOffset;
    FEnd := FStart + NewLen;
  end;
  Move(PWideChar(S)^, FPosition^, 2 * Len);
  Inc(FPosition, Len);
end;

procedure TWideBufferedString.AddNewLine;

var
  NewLen,
  LastOffset: Integer;

begin
  
  if FEnd - FPosition <= 4 then
  begin
    
    NewLen := FEnd - FStart + (2 + AllocIncrement - 1) and not (AllocIncrement - 1);
    
    LastOffset := FPosition - FStart;
    ReallocMem(FStart, 2 * NewLen);
    FPosition := FStart + LastOffset;
    FEnd := FStart + NewLen;
  end;
  FPosition^ := #13;
  Inc(FPosition);
  FPosition^ := #10;
  Inc(FPosition);
end;

constructor TCustomVirtualTreeOptions.Create(AOwner: TBaseVirtualTree);

begin
  FOwner := AOwner;

  FPaintOptions := DefaultPaintOptions;
  FAnimationOptions := DefaultAnimationOptions;
  FAutoOptions := DefaultAutoOptions;
  FSelectionOptions := DefaultSelectionOptions;
  FMiscOptions := DefaultMiscOptions;
end;

procedure TCustomVirtualTreeOptions.SetAnimationOptions(const Value: TVTAnimationOptions);

begin
  FAnimationOptions := Value;
end;

procedure TCustomVirtualTreeOptions.SetAutoOptions(const Value: TVTAutoOptions);

var
  ChangedOptions: TVTAutoOptions;

begin
  if FAutoOptions <> Value then
  begin
    
    ChangedOptions := FAutoOptions + Value - (FAutoOptions * Value);
    FAutoOptions := Value;
    with FOwner do
      if (toAutoSpanColumns in ChangedOptions) and not (csLoading in ComponentState) and HandleAllocated then
        Invalidate;
  end;
end;

procedure TCustomVirtualTreeOptions.SetMiscOptions(const Value: TVTMiscOptions);

var
  ToBeSet,
  ToBeCleared: TVTMiscOptions;

begin
  if FMiscOptions <> Value then
  begin
    ToBeSet := Value - FMiscOptions;
    ToBeCleared := FMiscOptions - Value;
    FMiscOptions := Value;

    with FOwner do
      if not (csLoading in ComponentState) and HandleAllocated then
      begin
        if toCheckSupport in ToBeSet + ToBeCleared then
          Invalidate;
        if not (csDesigning in ComponentState) then
        begin
          if toFullRepaintOnResize in TobeSet + ToBeCleared then
            RecreateWnd;
          if toAcceptOLEDrop in ToBeSet then
            RegisterDragDrop(Handle, DragManager as IDropTarget);
          if toAcceptOLEDrop in ToBeCleared then
            RevokeDragDrop(Handle);
        end;
      end;
  end;
end;

procedure TCustomVirtualTreeOptions.SetPaintOptions(const Value: TVTPaintOptions);

var
  ToBeSet,
  ToBeCleared: TVTPaintOptions;
  Run: PVirtualNode;
  HandleWasAllocated: Boolean;

begin
  if FPaintOptions <> Value then
  begin
    ToBeSet := Value - FPaintOptions;
    ToBeCleared := FPaintOptions - Value;
    FPaintOptions := Value;
    if (toFixedIndent in ToBeSet) then begin
      
      Include(FPaintOptions, toShowRoot);
      Include(ToBeSet, toShowRoot);
    end;
    with FOwner do
    begin
      HandleWasAllocated := HandleAllocated;

      if not (csLoading in ComponentState) and (toShowFilteredNodes in ToBeSet + ToBeCleared) then
      begin
        if HandleWasAllocated then
          BeginUpdate;
        InterruptValidation;
        Run := GetFirstNoInit;
        while Assigned(Run) do
        begin
          if (vsFiltered in Run.States) then
          begin
            if FullyVisible[Run] then
            begin
              if toShowFilteredNodes in ToBeSet then
                Inc(FVisibleCount)
              else
                Dec(FVisibleCount);
            end;
            if toShowFilteredNodes in ToBeSet then
              AdjustTotalHeight(Run, Run.NodeHeight, True)
            else
              AdjustTotalHeight(Run, -Run.NodeHeight, True);
          end;
          Run := GetNextNoInit(Run);
        end;
        if HandleWasAllocated then
          EndUpdate;
      end;

      if HandleAllocated then
      begin
        if IsWinVistaOrAbove and ((tsUseThemes in FStates) or
           ((toThemeAware in ToBeSet) and StyleServices.Enabled)) and
           (toUseExplorerTheme in (ToBeSet + ToBeCleared)) and not VclStyleEnabled then
          if (toUseExplorerTheme in ToBeSet) then
          begin
            SetWindowTheme('explorer');
            DoStateChange([tsUseExplorerTheme]);
          end
          else
            if toUseExplorerTheme in ToBeCleared then
            begin
              SetWindowTheme('');
              DoStateChange([], [tsUseExplorerTheme]);
            end;

        if not (csLoading in ComponentState) then
        begin
          if ((toThemeAware in ToBeSet + ToBeCleared) or (toUseExplorerTheme in ToBeSet + ToBeCleared) or VclStyleEnabled) then
          begin
            if ((toThemeAware in ToBeSet) and StyleServices.Enabled) or VclStyleEnabled then
              DoStateChange([tsUseThemes])
            else
              if (toThemeAware in ToBeCleared) then
              DoStateChange([], [tsUseThemes]);

            PrepareBitmaps(True, False);
            RedrawWindow(Handle, nil, 0, RDW_INVALIDATE or RDW_VALIDATE or RDW_FRAME);
          end;

          if toChildrenAbove in ToBeSet + ToBeCleared then
          begin
            InvalidateCache;
            if FUpdateCount = 0 then
            begin
              ValidateCache;
              Invalidate;
            end;
          end;

          Invalidate;
        end;
      end;
    end;
  end;
end;

procedure TCustomVirtualTreeOptions.SetSelectionOptions(const Value: TVTSelectionOptions);

var
  ToBeSet,
  ToBeCleared: TVTSelectionOptions;

begin
  if FSelectionOptions <> Value then
  begin
    ToBeSet := Value - FSelectionOptions;
    ToBeCleared := FSelectionOptions - Value;
    FSelectionOptions := Value;

    with FOwner do
    begin
      if (toMultiSelect in (ToBeCleared + ToBeSet)) or
        ([toLevelSelectConstraint, toSiblingSelectConstraint] * ToBeSet <> []) then
        ClearSelection;

      if (toExtendedFocus in ToBeCleared) and (FFocusedColumn > 0) and HandleAllocated then
      begin
        FFocusedColumn := FHeader.MainColumn;
        Invalidate;
      end;

      if not (toExtendedFocus in FSelectionOptions) then
        FFocusedColumn := FHeader.MainColumn;
    end;
  end;
end;

procedure TCustomVirtualTreeOptions.AssignTo(Dest: TPersistent);

begin
  if Dest is TCustomVirtualTreeOptions then
  begin
    with Dest as TCustomVirtualTreeOptions do
    begin
      PaintOptions := Self.PaintOptions;
      AnimationOptions := Self.AnimationOptions;
      AutoOptions := Self.AutoOptions;
      SelectionOptions := Self.SelectionOptions;
      MiscOptions := Self.MiscOptions;
    end;
  end
  else
    inherited;
end;

constructor TEnumFormatEtc.Create(Tree: TBaseVirtualTree; AFormatEtcArray: TFormatEtcArray);

var
  I: Integer;

begin
  inherited Create;

  FTree := Tree;
  
  SetLength(FFormatEtcArray, Length(AFormatEtcArray));
  for I := 0 to High(AFormatEtcArray) do
    FFormatEtcArray[I] := AFormatEtcArray[I];
end;

function TEnumFormatEtc.Clone(out Enum: IEnumFormatEtc): HResult;

var
  AClone: TEnumFormatEtc;

begin
  Result := S_OK;
  try
    AClone := TEnumFormatEtc.Create(nil, FFormatEtcArray);
    AClone.FCurrentIndex := FCurrentIndex;
    Enum := AClone as IEnumFormatEtc;
  except
    Result := E_FAIL;
  end;
end;

function TEnumFormatEtc.Next(celt: Integer; out elt; pceltFetched: PLongint): HResult;

var
  CopyCount: Integer;

begin
  Result := S_FALSE;
  CopyCount := Length(FFormatEtcArray) - FCurrentIndex;
  if celt < CopyCount then
    CopyCount := celt;
  if CopyCount > 0 then
  begin
    Move(FFormatEtcArray[FCurrentIndex], elt, CopyCount * SizeOf(TFormatEtc));
    Inc(FCurrentIndex, CopyCount);
    Result := S_OK;
  end;
  if Assigned(pceltFetched) then
    pceltFetched^ := CopyCount;
end;

function TEnumFormatEtc.Reset: HResult;

begin
  FCurrentIndex := 0;
  Result := S_OK;
end;

function TEnumFormatEtc.Skip(celt: Integer): HResult;

begin
  if FCurrentIndex + celt < High(FFormatEtcArray) then
  begin
    Inc(FCurrentIndex, celt);
    Result := S_Ok;
  end
  else
    Result := S_FALSE;
end;

constructor TVTDataObject.Create(AOwner: TBaseVirtualTree; ForClipboard: Boolean);

begin
  inherited Create;

  FOwner := AOwner;
  FForClipboard := ForClipboard;
  FOwner.GetNativeClipboardFormats(FFormatEtcArray);
end;

destructor TVTDataObject.Destroy;

var
  I: Integer;
  StgMedium: PStgMedium;

begin
  
  if FForClipboard and not (tsClipboardFlushing in FOwner.FStates) then
    FOwner.CancelCutOrCopy;
  
  for I := 0 to High(FormatEtcArray) do
  begin
    StgMedium := FindInternalStgMedium(FormatEtcArray[I].cfFormat);
    if Assigned(StgMedium) then
      ReleaseStgMedium(StgMedium^);
  end;

  FormatEtcArray := nil;
  inherited;
end;

function TVTDataObject.CanonicalIUnknown(TestUnknown: IUnknown): IUnknown;

begin
  if Assigned(TestUnknown) then
  begin
    if TestUnknown.QueryInterface(IUnknown, Result) = 0 then
      Result._Release 
    else
      Result := TestUnknown
  end
  else
    Result := TestUnknown
end;

function TVTDataObject.EqualFormatEtc(FormatEtc1, FormatEtc2: TFormatEtc): Boolean;

begin
  Result := (FormatEtc1.cfFormat = FormatEtc2.cfFormat) and (FormatEtc1.ptd = FormatEtc2.ptd) and
    (FormatEtc1.dwAspect = FormatEtc2.dwAspect) and (FormatEtc1.lindex = FormatEtc2.lindex) and
    (FormatEtc1.tymed and FormatEtc2.tymed <> 0);
end;

function TVTDataObject.FindFormatEtc(TestFormatEtc: TFormatEtc; const FormatEtcArray: TFormatEtcArray): integer;

var
  I: integer;

begin
  Result := -1;
  for I := 0 to High(FormatEtcArray) do
  begin
    if EqualFormatEtc(TestFormatEtc, FormatEtcArray[I]) then
    begin
      Result := I;
      Break;
    end
  end;
end;

function TVTDataObject.FindInternalStgMedium(Format: TClipFormat): PStgMedium;

var
  I: integer;
begin
  Result := nil;
  for I := 0 to High(InternalStgMediumArray) do
  begin
    if Format = InternalStgMediumArray[I].Format then
    begin
      Result := @InternalStgMediumArray[I].Medium;
      Break;
    end
  end;
end;

function TVTDataObject.HGlobalClone(HGlobal: THandle): THandle;

var
  Size: Cardinal;
  Data,
  NewData: PByte;

begin
  Size := GlobalSize(HGlobal);
  Result := GlobalAlloc(GPTR, Size);
  Data := GlobalLock(hGlobal);
  try
    NewData := GlobalLock(Result);
    try
      Move(Data^, NewData^, Size);
    finally
      GlobalUnLock(Result);
    end
  finally
    GlobalUnLock(hGlobal);
  end
end;

function TVTDataObject.RenderInternalOLEData(const FormatEtcIn: TFormatEtc; var Medium: TStgMedium;
  var OLEResult: HResult): Boolean;

var
  InternalMedium: PStgMedium;

begin
  Result := True;
  InternalMedium := FindInternalStgMedium(FormatEtcIn.cfFormat);
  if Assigned(InternalMedium) then
    OLEResult := StgMediumIncRef(InternalMedium^, Medium, False, Self as IDataObject)
  else
    Result := False;
end;

function TVTDataObject.StgMediumIncRef(const InStgMedium: TStgMedium; var OutStgMedium: TStgMedium;
  CopyInMedium: Boolean; DataObject: IDataObject): HRESULT;

var
  Len: Integer;

begin
  Result := S_OK;
  
  OutStgMedium := InStgMedium;
  
  case InStgMedium.tymed of
    TYMED_HGLOBAL:
      begin
        if CopyInMedium then
        begin
          
          OutStgMedium.hGlobal := HGlobalClone(InStgMedium.hGlobal);
          if OutStgMedium.hGlobal = 0 then
            Result := E_OUTOFMEMORY
        end
        else
          
          OutStgMedium.unkForRelease := Pointer(DataObject); 
      end;
    TYMED_FILE:
      begin
        Len := lstrLenW(InStgMedium.lpszFileName) + 1; 
        OutStgMedium.lpszFileName := CoTaskMemAlloc(2 * Len);
        Move(InStgMedium.lpszFileName^, OutStgMedium.lpszFileName^, 2 * Len);
      end;
    TYMED_ISTREAM:
      IUnknown(OutStgMedium.stm)._AddRef;
    TYMED_ISTORAGE:
      IUnknown(OutStgMedium.stg)._AddRef;
    TYMED_GDI:
      if not CopyInMedium then
        
        OutStgMedium.unkForRelease := Pointer(DataObject) 
      else
        Result := DV_E_TYMED; 
    TYMED_MFPICT:
      if not CopyInMedium then
        
        OutStgMedium.unkForRelease := Pointer(DataObject) 
      else
        Result := DV_E_TYMED; 
    TYMED_ENHMF:
      if not CopyInMedium then
        
        OutStgMedium.unkForRelease := Pointer(DataObject) 
      else
        Result := DV_E_TYMED; 
  else
    Result := DV_E_TYMED;
  end;

  if (Result = S_OK) and Assigned(OutStgMedium.unkForRelease) then
    IUnknown(OutStgMedium.unkForRelease)._AddRef;
end;

function TVTDataObject.DAdvise(const FormatEtc: TFormatEtc; advf: Integer; const advSink: IAdviseSink;
  out dwConnection: Integer): HResult;

begin
  Result := S_OK;
  if FAdviseHolder = nil then
    Result := CreateDataAdviseHolder(FAdviseHolder);
  if Result = S_OK then
    Result := FAdviseHolder.Advise(Self as IDataObject, FormatEtc, advf, advSink, dwConnection);
end;

function TVTDataObject.DUnadvise(dwConnection: Integer): HResult;

begin
  if FAdviseHolder = nil then
    Result := E_NOTIMPL
  else
    Result := FAdviseHolder.Unadvise(dwConnection);
end;

function TVTDataObject.EnumDAdvise(out enumAdvise: IEnumStatData): HResult;

begin
  if FAdviseHolder = nil then
    Result := OLE_E_ADVISENOTSUPPORTED
  else
    Result := FAdviseHolder.EnumAdvise(enumAdvise);
end;

function TVTDataObject.EnumFormatEtc(Direction: Integer; out EnumFormatEtc: IEnumFormatEtc): HResult;

var
  NewList: TEnumFormatEtc;

begin
  Result := E_FAIL;
  if Direction = DATADIR_GET then
  begin
    NewList := TEnumFormatEtc.Create(FOwner, FormatEtcArray);
    EnumFormatEtc := NewList as IEnumFormatEtc;
    Result := S_OK;
  end
  else
    EnumFormatEtc := nil;
  if EnumFormatEtc = nil then
    Result := OLE_S_USEREG;
end;

function TVTDataObject.GetCanonicalFormatEtc(const FormatEtc: TFormatEtc; out FormatEtcOut: TFormatEtc): HResult;

begin
  Result := DATA_S_SAMEFORMATETC;
end;

function TVTDataObject.GetData(const FormatEtcIn: TFormatEtc; out Medium: TStgMedium): HResult;

var
  I: Integer;
  Data: PVTReference;

begin
  
  if FormatEtcIn.cfFormat = CF_VTREFERENCE then
  begin
    
    if tsClipboardFlushing in FOwner.FStates then
      Result := E_FAIL
    else
    begin
      Medium.hGlobal := GlobalAlloc(GHND or GMEM_SHARE, SizeOf(TVTReference));
      Data := GlobalLock(Medium.hGlobal);
      Data.Process := GetCurrentProcessID;
      Data.Tree := FOwner;
      GlobalUnlock(Medium.hGlobal);
      Medium.tymed := TYMED_HGLOBAL;
      Medium.unkForRelease := nil;
      Result := S_OK;
    end;
  end
  else
  begin
    try
      
      Result := QueryGetData(FormatEtcIn);
      if Result = S_OK then
      begin
        for I := 0 to High(FormatEtcArray) do
        begin
          if EqualFormatEtc(FormatEtcIn, FormatEtcArray[I]) then
          begin
            if not RenderInternalOLEData(FormatEtcIn, Medium, Result) then
              Result := FOwner.RenderOLEData(FormatEtcIn, Medium, FForClipboard);
            Break;
          end;
        end
      end
    except
      ZeroMemory (@Medium, SizeOf(Medium));
      Result := E_FAIL;
    end;
  end;
end;

function TVTDataObject.GetDataHere(const FormatEtc: TFormatEtc; out Medium: TStgMedium): HResult;

begin
  Result := E_NOTIMPL;
end;

function TVTDataObject.QueryGetData(const FormatEtc: TFormatEtc): HResult;

var
  I: Integer;

begin
  Result := DV_E_CLIPFORMAT;
  for I := 0 to High(FFormatEtcArray) do
  begin
    if FormatEtc.cfFormat = FFormatEtcArray[I].cfFormat then
    begin
      if (FormatEtc.tymed and FFormatEtcArray[I].tymed) <> 0 then
      begin
        if FormatEtc.dwAspect = FFormatEtcArray[I].dwAspect then
        begin
          if FormatEtc.lindex = FFormatEtcArray[I].lindex then
          begin
            Result := S_OK;
            Break;
          end
          else
            Result := DV_E_LINDEX;
        end
        else
          Result := DV_E_DVASPECT;
      end
      else
        Result := DV_E_TYMED;
    end;
  end
end;

function TVTDataObject.SetData(const FormatEtc: TFormatEtc; var Medium: TStgMedium; DoRelease: BOOL): HResult;

var
  Index: Integer;
  LocalStgMedium: PStgMedium;

begin
  
  Index := FindFormatEtc(FormatEtc, FormatEtcArray);
  if Index > - 1 then
  begin
    
    LocalStgMedium := FindInternalStgMedium(FormatEtcArray[Index].cfFormat);
    if Assigned(LocalStgMedium) then
    begin
      ReleaseStgMedium(LocalStgMedium^);
      ZeroMemory(LocalStgMedium, SizeOf(LocalStgMedium^));
    end;
  end
  else
  begin
    
    SetLength(FFormatEtcArray, Length(FormatEtcArray) + 1);
    FormatEtcArray[High(FormatEtcArray)] := FormatEtc;
    
    SetLength(FInternalStgMediumArray, Length(InternalStgMediumArray) + 1);
    InternalStgMediumArray[High(InternalStgMediumArray)].Format := FormatEtc.cfFormat;
    LocalStgMedium := @InternalStgMediumArray[High(InternalStgMediumArray)].Medium;
    ZeroMemory(LocalStgMedium, SizeOf(LocalStgMedium^));
  end;

  if DoRelease then
  begin
    
    LocalStgMedium^ := Medium;
    Result := S_OK
  end
  else
  begin
    
    Result := StgMediumIncRef(Medium, LocalStgMedium^, True, Self as IDataObject);
    
    if Assigned(LocalStgMedium.unkForRelease) then
    begin
      if CanonicalIUnknown(Self) = CanonicalIUnknown(IUnknown(LocalStgMedium.unkForRelease)) then
        IUnknown(LocalStgMedium.unkForRelease) := nil; 
    end;
  end;
  
  if Assigned(FAdviseHolder) then
    FAdviseHolder.SendOnDataChange(Self as IDataObject, 0, 0);
end;

constructor TVTDragManager.Create(AOwner: TBaseVirtualTree);

begin
  inherited Create;
  FOwner := AOwner;
  
  CoCreateInstance(CLSID_DragDropHelper, nil, CLSCTX_INPROC_SERVER, IID_IDropTargetHelper, FDropTargetHelper);
end;

destructor TVTDragManager.Destroy;

begin
  
  Pointer(FOwner.FDragManager) := nil;
  inherited;
end;

function TVTDragManager.GetDataObject: IDataObject;

begin
  
  if Assigned(FDataObject) then
    Result := FDataObject
  else
  begin
    Result := FOwner.DoCreateDataObject;
    if Result = nil then
      Result := TVTDataObject.Create(FOwner, False) as IDataObject;
  end;
end;

function TVTDragManager.GetDragSource: TBaseVirtualTree;

begin
  Result := FDragSource;
end;

function TVTDragManager.GetDropTargetHelperSupported: Boolean;

begin
  Result := Assigned(FDropTargetHelper);
end;

function TVTDragManager.GetIsDropTarget: Boolean;

begin
  Result := FIsDropTarget;
end;

function TVTDragManager.DragEnter(const DataObject: IDataObject; KeyState: Integer; Pt: TPoint;
  var Effect: Integer): HResult;

begin
  FDataObject := DataObject;
  FIsDropTarget := True;

  SystemParametersInfo(SPI_GETDRAGFULLWINDOWS, 0, @FFullDragging, 0);
  
  if not FFullDragging then
    LockWindowUpdate(0);
  if Assigned(FDropTargetHelper) and FFullDragging then
    FDropTargetHelper.DragEnter(FOwner.Handle, DataObject, Pt, Effect);

  FDragSource := FOwner.GetTreeFromDataObject(DataObject);
  Result := FOwner.DragEnter(KeyState, Pt, Effect);
end;

function TVTDragManager.DragLeave: HResult;

begin
  if Assigned(FDropTargetHelper) and FFullDragging then
    FDropTargetHelper.DragLeave;

  FOwner.DragLeave;
  FIsDropTarget := False;
  FDragSource := nil;
  FDataObject := nil;
  Result := NOERROR;
end;

function TVTDragManager.DragOver(KeyState: Integer; Pt: TPoint; var Effect: LongInt): HResult;

begin
  if Assigned(FDropTargetHelper) and FFullDragging then
    FDropTargetHelper.DragOver(Pt, Effect);

  Result := FOwner.DragOver(FDragSource, KeyState, dsDragMove, Pt, Effect);
end;

function TVTDragManager.Drop(const DataObject: IDataObject; KeyState: Integer; Pt: TPoint;
  var Effect: Integer): HResult;

begin
  if Assigned(FDropTargetHelper) and FFullDragging then
    FDropTargetHelper.Drop(DataObject, Pt, Effect);

  Result := FOwner.DragDrop(DataObject, KeyState, Pt, Effect);
  FIsDropTarget := False;
  FDataObject := nil;
end;

procedure TVTDragManager.ForceDragLeave;

begin
  if Assigned(FDropTargetHelper) and FFullDragging then
    FDropTargetHelper.DragLeave;
end;

function TVTDragManager.GiveFeedback(Effect: Integer): HResult;

begin
  Result := DRAGDROP_S_USEDEFAULTCURSORS;
end;

function TVTDragManager.QueryContinueDrag(EscapePressed: BOOL; KeyState: Integer): HResult;

var
  RButton,
  LButton: Boolean;

begin
  LButton := (KeyState and MK_LBUTTON) <> 0;
  RButton := (KeyState and MK_RBUTTON) <> 0;
  
  if (LButton and RButton) or EscapePressed then
    Result := DRAGDROP_S_CANCEL
  else
    
    if not (LButton or RButton) then
      Result := DRAGDROP_S_DROP
    else
      Result := S_OK;
end;

var
  
  FHintWindowDestroyed: Boolean = True;

constructor TVirtualTreeHintWindow.Create(AOwner: TComponent);

begin
  inherited;

  FBackground := TBitmap.Create;
  FBackground.PixelFormat := pf32Bit;
  FDrawBuffer := TBitmap.Create;
  FDrawBuffer.PixelFormat := pf32Bit;
  FTarget := TBitmap.Create;
  FTarget.PixelFormat := pf32Bit;

  DoubleBuffered := False; 
  FHintWindowDestroyed := False;
end;

destructor TVirtualTreeHintWindow.Destroy;

begin
  FHintWindowDestroyed := True;

  FTarget.Free;
  FDrawBuffer.Free;
  FBackground.Free;
  inherited;
end;

function TVirtualTreeHintWindow.AnimationCallback(Step, StepSize: Integer; Data: Pointer): Boolean;

begin
  Result := not FHintWindowDestroyed and HandleAllocated and IsWindowVisible(Handle) and
    Assigned(FHintData.Tree) and not (tsCancelHintAnimation in FHintData.Tree.FStates);
  if Result then
  begin
    InternalPaint(Step, StepSize);
    
    Application.ProcessMessages;
  end;
end;

procedure TVirtualTreeHintWindow.CMTextChanged(var Message: TMessage);

begin
  
end;

function TVirtualTreeHintWindow.GetHintWindowDestroyed;

begin
  Result := FHintWindowDestroyed;
end;

procedure TVirtualTreeHintWindow.WMEraseBkgnd(var Message: TWMEraseBkgnd);

begin
  Message.Result := 1;
end;

procedure TVirtualTreeHintWindow.WMNCPaint(var Message: TMessage);

begin
  Message.Result := 0;
end;

procedure TVirtualTreeHintWindow.WMShowWindow(var Message: TWMShowWindow);

begin
  if not Message.Show then
  begin
    
    Finalize(FHintData);
    ZeroMemory (@FHintData, SizeOf(FHintData));
    
    FHintWindowDestroyed := False;
  end;
end;

procedure TVirtualTreeHintWindow.CreateParams(var Params: TCreateParams);

begin
  inherited CreateParams(Params);

  with Params do
  begin
    Style := WS_POPUP;
    ExStyle := ExStyle and not WS_EX_CLIENTEDGE;
  end;
end;

procedure TVirtualTreeHintWindow.InternalPaint(Step, StepSize: Integer);

  procedure DoShadowBlend(DC: HDC; R: TRect; Alpha: Integer);

  begin
    AlphaBlend(0, DC, R, Point(0, 0), bmConstantAlphaAndColor,  Alpha, clBlack);
  end;

  procedure DrawHintShadow(Canvas: TCanvas; ShadowSize: Integer);

  var
    R: TRect;

  begin
    
    R := Rect(ShadowSize, Height - ShadowSize, Width, Height);
    DoShadowBlend(Canvas.Handle, R, 5);
    Inc(R.Left);
    Dec(R.Right);
    Dec(R.Bottom);
    DoShadowBlend(Canvas.Handle, R, 10);
    Inc(R.Left);
    Dec(R.Right);
    Dec(R.Bottom);
    DoShadowBlend(Canvas.Handle, R, 20);
    Inc(R.Left);
    Dec(R.Right);
    Dec(R.Bottom);
    DoShadowBlend(Canvas.Handle, R, 35);
    Inc(R.Left);
    Dec(R.Right);
    Dec(R.Bottom);
    DoShadowBlend(Canvas.Handle, R, 50);
    
    R := Rect(Width - ShadowSize, ShadowSize, Width, Height - ShadowSize);
    DoShadowBlend(Canvas.Handle, R, 5);
    Inc(R.Top);
    Dec(R.Right);
    DoShadowBlend(Canvas.Handle, R, 10);
    Inc(R.Top);
    Dec(R.Right);
    DoShadowBlend(Canvas.Handle, R, 20);
    Inc(R.Top);
    Dec(R.Right);
    DoShadowBlend(Canvas.Handle, R, 35);
    Inc(R.Top);
    Dec(R.Right);
    DoShadowBlend(Canvas.Handle, R, 50);
  end;

var
  R: TRect;
  Y: Integer;
  S: UnicodeString;
  DrawFormat: Cardinal;
  Shadow: Integer;
  HintKind: TVTHintKind;
  LClipRect: TRect;

  {$IF CompilerVersion >= 23 }
  LColor: TColor;
  LDetails: TThemedElementDetails;
  LGradientStart: TColor;
  LGradientEnd: TColor;
  {$IFEND}

begin
  Shadow := 0;

  with FHintData, FDrawBuffer do
  begin
    
    if Step = 0 then
    begin
      
      if (Node = nil) or (Tree.FHintMode <> hmToolTip) then
      begin
        Canvas.Font := Screen.HintFont;
        Y := 2;
      end
      else
      begin
        Tree.GetTextInfo(Node, Column, Canvas.Font, R, S);
        if LineBreakStyle = hlbForceMultiLine then
          Y := 1
        else
          Y := (R.Top - R.Bottom - Shadow + Self.Height) div 2;
      end;

      R := Rect(0, 0, Width - Shadow, Height - Shadow);

      HintKind := vhkText;
      if Assigned(Node) then
        Tree.DoGetHintKind(Node, Column, HintKind);

      if HintKind = vhkOwnerDraw then
      begin
        Tree.DoDrawHint(Canvas, Node, R, Column);
      end
      else
        with Canvas do
        begin
          {$IF CompilerVersion >= 23 }
          if Tree.VclStyleEnabled  then
          begin
            LDetails := StyleServices.GetElementDetails(thHintNormal);
            if StyleServices.GetElementColor(LDetails, ecGradientColor1, LColor) and (LColor <> clNone) then
              LGradientStart := LColor
            else
              LGradientStart := clInfoBk;
            if StyleServices.GetElementColor(LDetails, ecGradientColor2, LColor) and (LColor <> clNone) then
              LGradientEnd := LColor
            else
              LGradientEnd := clInfoBk;
            if StyleServices.GetElementColor(LDetails, ecTextColor, LColor) and (LColor <> clNone) then
              Font.Color := LColor
            else
              Font.Color := Screen.HintFont.Color;
            GradientFillCanvas(Canvas, LGradientStart, LGradientEnd, R, gdVertical);
          end
          else
          {$IFEND}
            begin
            
            Font.Color := clInfoText;
            Pen.Color := clBlack;
            Brush.Color := clInfoBk;
            if IsWinVistaOrAbove and StyleServices.Enabled and ((toThemeAware in Tree.TreeOptions.PaintOptions) or
               (toUseExplorerTheme in Tree.TreeOptions.PaintOptions)) then
            begin
              if toUseExplorerTheme in Tree.TreeOptions.PaintOptions then 
                StyleServices.DrawElement(Canvas.Handle, StyleServices.GetElementDetails(tttStandardNormal), R)
              else
                begin 
                  LClipRect := R;
                  InflateRect(R, 4, 4);
                  StyleServices.DrawElement(Handle, StyleServices.GetElementDetails(tttStandardNormal), R, @LClipRect);
                  R := LClipRect;
                  StyleServices.DrawEdge(Handle, StyleServices.GetElementDetails(twWindowRoot), R, [eeRaisedOuter], [efRect]);
                end;
            end
            else
              if Tree.VclStyleEnabled then
                StyleServices.DrawElement(Canvas.Handle, StyleServices.GetElementDetails(tttStandardNormal), R)
              else
                Rectangle(R);
          end;
          
          InflateRect(R, -1, -1);
          DrawFormat := DT_TOP or DT_NOPREFIX;
          SetBkMode(Handle, Windows.TRANSPARENT);
          R.Top := Y;
          R.Left := R.Left + 3; 
          if Assigned(Node) and (LineBreakStyle = hlbForceMultiLine) then
            DrawFormat := DrawFormat or DT_WORDBREAK;
          Windows.DrawTextW(Handle, PWideChar(HintText), Length(HintText), R, DrawFormat)
        end;
    end;
  end;

    if StepSize > 0 then
      begin
        if FHintData.Tree.DoGetAnimationType = hatFade then
        begin
          with FTarget do
            BitBlt(Canvas.Handle, 0, 0, Width, Height, FBackground.Canvas.Handle, 0, 0, SRCCOPY);
          
          AlphaBlend(FDrawBuffer.Canvas.Handle, FTarget.Canvas.Handle, Rect(0, 0, Width - Shadow, Height - Shadow),
            Point(0, 0), bmConstantAlpha,  MulDiv(Step, 256, FadeAnimationStepCount), 0);

          if Shadow > 0 then
            DrawHintShadow(FTarget.Canvas, Shadow);
          BitBlt(Canvas.Handle, 0, 0, Width, Height, FTarget.Canvas.Handle, 0, 0, SRCCOPY);
        end
        else
        begin
          
          BitBlt(Canvas.Handle, 0, 0, Width - Shadow, Step, FDrawBuffer.Canvas.Handle, 0, Height - Step, SRCCOPY);
          
          if Step <= Shadow then
            Step := 0
          else
            Dec(Step, Shadow);
          BitBlt(Canvas.Handle, 0, Step, Width, Height - Step, FBackground.Canvas.Handle, 0, Step, SRCCOPY);
        end;
      end
      else
        
        if FHintData.Tree.DoGetAnimationType <> hatFade then
        begin
          if Shadow > 0 then
          begin
            with FBackground do
              BitBlt(Canvas.Handle, 0, 0, Width - Shadow, Height - Shadow, FDrawBuffer.Canvas.Handle, 0, 0, SRCCOPY);

            DrawHintShadow(FBackground.Canvas, Shadow);
            BitBlt(Canvas.Handle, 0, 0, Width, Height, FBackground.Canvas.Handle, 0, 0, SRCCOPY);
          end
          else
            BitBlt(Canvas.Handle, 0, 0, Width, Height, FDrawBuffer.Canvas.Handle, 0, 0, SRCCOPY);
        end;

end;

procedure TVirtualTreeHintWindow.Paint;

begin
  InternalPaint(0, 0);
end;

procedure TVirtualTreeHintWindow.ActivateHint(Rect: TRect; const AHint: string);

var
  DC: HDC;
  StopLastAnimation: Boolean;

begin
  if IsRectEmpty(Rect) or not Assigned(FHintData.Tree) then
    Application.CancelHint
  else
  begin
    
    StopLastAnimation := (tsInAnimation in FHintData.Tree.FStates);
    if StopLastAnimation then
      FHintData.Tree.DoStateChange([], [tsInAnimation]);

    SetWindowPos(Handle, 0, Rect.Left, Rect.Top, Width, Height, SWP_HIDEWINDOW or SWP_NOACTIVATE or SWP_NOZORDER);
    UpdateBoundsRect(Rect);
    
    if Rect.Top - Screen.DesktopTop + Height > Screen.DesktopHeight then
      Rect.Top := Screen.DesktopHeight - Height + Screen.DesktopTop;
    if Rect.Left - Screen.DesktopLeft + Width > Screen.DesktopWidth then
      Rect.Left := Screen.DesktopWidth - Width + Screen.DesktopLeft;
    if Rect.Bottom - Screen.DesktopTop < Screen.DesktopTop then
      Rect.Bottom := Screen.DesktopTop + Screen.DesktopTop;
    if Rect.Left - Screen.DesktopLeft < Screen.DesktopLeft then
      Rect.Left := Screen.DesktopLeft + Screen.DesktopLeft;
    
    FDrawBuffer.Width := Width;
    FDrawBuffer.Height := Height;
    FBackground.Width := Width;
    FBackground.Height := Height;
    FTarget.Width := Width;
    FTarget.Height := Height;

    FHintData.Tree.Update;
    
    DC := GetDC(0);
    try
      with TWithSafeRect(Rect) do
        BitBlt(FBackground.Canvas.Handle, 0, 0, Width, Height, DC, Left, Top, SRCCOPY);
    finally
      ReleaseDC(0, DC);
    end;

    SetWindowPos(Handle, HWND_TOPMOST, Rect.Left, Rect.Top, Width, Height, SWP_SHOWWINDOW or SWP_NOACTIVATE);
    with FHintData.Tree do
      case DoGetAnimationType of
        hatNone:
          InvalidateRect(Self.Handle, nil, False);
        hatFade:
          begin
            
            ValidateRect(Self.Handle, nil);
            
            Animate(FadeAnimationStepCount, 2 * FAnimationDuration, AnimationCallback, nil);
          end;
        hatSlide:
          begin
            
            ValidateRect(Self.Handle, nil);
            Animate(Self.Height, FAnimationDuration, AnimationCallback, nil);
          end;
      end;
    if not FHintWindowDestroyed and StopLastAnimation and Assigned(FHintData.Tree) then
      FHintData.Tree.DoStateChange([tsCancelHintAnimation]);
  end;
end;

function TVirtualTreeHintWindow.CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect;

var
  TM: TTextMetric;
  R: TRect;

begin
  if AData = nil then
    
    Result := Rect(0, 0, 0, 0)
  else
  begin
    
    BidiMode := bdLeftToRight;

    FHintData := PVTHintData(AData)^;

    with FHintData do
    begin
      
      if Assigned(Node) and (not IsRectEmpty(HintRect)) then
        Result := HintRect
      else
      begin
        if Column <= NoColumn then
        begin
          BidiMode := Tree.BidiMode;
          Alignment := Tree.Alignment;
        end
        else
        begin
          BidiMode := Tree.Header.Columns[Column].BidiMode;
          Alignment := Tree.Header.Columns[Column].Alignment;
        end;

        if BidiMode <> bdLeftToRight then
          ChangeBidiModeAlignment(Alignment);

        if (Node = nil) or (Tree.FHintMode <> hmToolTip) then
          Canvas.Font := Screen.HintFont
        else
        begin
          Canvas.Font := Tree.Font;
          if Tree is TCustomVirtualStringTree then
            with TCustomVirtualStringTree(Tree) do
              DoPaintText(Node, Self.Canvas, Column, ttNormal);
        end;

        GetTextMetrics(Canvas.Handle, TM);
        FTextHeight := TM.tmHeight;
        LineBreakStyle := hlbDefault;

        if Length(DefaultHint) > 0 then
          HintText := DefaultHint
        else
          if Tree.HintMode = hmToolTip then
            HintText := Tree.DoGetNodeToolTip(Node, Column, LineBreakStyle)
          else
            HintText := Tree.DoGetNodeHint(Node, Column, LineBreakStyle);

        if Length(HintText) = 0 then
          Result := Rect(0, 0, 0, 0)
        else
        begin
          if Assigned(Node) and (Tree.FHintMode = hmToolTip) then
          begin
            
            if LineBreakStyle = hlbDefault then
              if vsMultiline in Node.States then
                LineBreakStyle := hlbForceMultiLine
              else
                LineBreakStyle := hlbForceSingleLine;
            
            if LineBreakStyle = hlbForceMultiLine then
            begin
              
              Result := Tree.GetDisplayRect(Node, Column, True, False);
              R := Result;
              
              Windows.DrawTextW(Canvas.Handle, PWideChar(HintText), Length(HintText), R, DT_CALCRECT or DT_WORDBREAK);
              if BidiMode = bdLeftToRight then
                Result.Right := R.Right + Tree.FTextMargin
              else
                Result.Left := R.Left - Tree.FTextMargin + 1;
              Result.Bottom := R.Bottom;

              Inc(Result.Right);
              
              if (Tree.Header.Columns.Count > 0) and ((Integer(Tree.NodeHeight[Node]) + 2) >= (Result.Bottom - Result.Top)) and
                 ((Tree.Header.Columns[Column].Width + 2) >= (Result.Right - Result.Left)) and not
                 ((Result.Left < 0) or (Result.Right > Tree.ClientWidth + 3) or
                  (Result.Top < 0) or (Result.Bottom > Tree.ClientHeight + 3)) then
              begin
                Result := Rect(0, 0, 0, 0);
                Exit;
              end;
            end
            else
            begin
              Result := Tree.FLastHintRect; 
              if toShowHorzGridLines in Tree.TreeOptions.PaintOptions then
                Dec(Result.Bottom);
            end;
            
            InflateRect(Result, 1, 1);
            
            OffsetRect(Result, -Result.Left - 1, -Result.Top - 1);
          end
          else
          begin
            
            Result := Rect(0, 0, MaxWidth, FTextHeight);
            
            Windows.DrawTextW(Canvas.Handle, PWideChar(HintText), Length(HintText), Result, DT_CALCRECT or DT_TOP or DT_NOPREFIX or DT_WORDBREAK);
            
            Inc(Result.Bottom, 6);
            
            If not Assigned(Tree) then exit;
            Inc(Result.Right, Tree.FTextMargin + FTextHeight); 
          end;
        end;
      end;
    end;
  end;
end;

function TVirtualTreeHintWindow.IsHintMsg(var Msg: TMsg): Boolean;

begin
  Result := inherited IsHintMsg(Msg) and HandleAllocated and IsWindowVisible(Handle);
  
  if Result and ((Msg.Message = WM_NCMOUSEMOVE) or ((Msg.Message >= WM_KEYFIRST) and (Msg.Message <= WM_KEYLAST))) then
    Result := False
  else
    
    if HandleAllocated and IsWindowVisible(Handle) and (Msg.Message >= WM_KEYFIRST) and (Msg.Message <= WM_KEYLAST) and
      (tsInAnimation in FHintData.Tree.FStates) and TranslateMessage(Msg) then
      DispatchMessage(Msg);
end;

constructor TVTDragImage.Create(AOwner: TBaseVirtualTree);

begin
  FOwner := AOwner;
  FTransparency := 128;
  FPreBlendBias := 0;
  FPostBlendBias := 0;
  FFade := False;
  FRestriction := dmrNone;
  FColorKey := clNone;
end;

destructor TVTDragImage.Destroy;

begin
  EndDrag;

  inherited;
end;

function TVTDragImage.GetVisible: Boolean;

begin
  Result := FStates * [disHidden, disInDrag, disPrepared, disSystemSupport] = [disInDrag, disPrepared];
end;

procedure TVTDragImage.InternalShowDragImage(ScreenDC: HDC);

var
  BlendMode: TBlendMode;

begin
  with FAlphaImage do
    BitBlt(Canvas.Handle, 0, 0, Width, Height, FBackImage.Canvas.Handle, 0, 0, SRCCOPY);
  if not FFade and (FColorKey = clNone) then
    BlendMode := bmConstantAlpha
  else
    BlendMode := bmMasterAlpha;
  with FDragImage do
    AlphaBlend(Canvas.Handle, FAlphaImage.Canvas.Handle, Rect(0, 0, Width, Height), Point(0, 0), BlendMode,
      FTransparency, FPostBlendBias);

  with FAlphaImage do
    BitBlt(ScreenDC, FImagePosition.X, FImagePosition.Y, Width, Height, Canvas.Handle, 0, 0, SRCCOPY);
end;

procedure TVTDragImage.MakeAlphaChannel(Source, Target: TBitmap);

type
  PBGRA = ^TBGRA;
  TBGRA = packed record
    case Boolean of
      False:
        (Color: Cardinal);
      True:
        (BGR: array[0..2] of Byte;
         Alpha: Byte);
  end;

var
  Color,
  ColorKeyRef: COLORREF;
  UseColorKey: Boolean;
  SourceRun,
  TargetRun: PBGRA;
  X, Y,
  MaxDimension,
  HalfWidth,
  HalfHeight: Integer;
  T: Extended;

begin
  UseColorKey := ColorKey <> clNone;
  ColorKeyRef := ColorToRGB(ColorKey) and $FFFFFF;
  
  with TBGRA(ColorKeyRef) do
  begin
    X := BGR[0];
    BGR[0] := BGR[2];
    BGR[2] := X;
  end;

  with Target do
  begin
    MaxDimension := Max(Width, Height);

    HalfWidth := Width div 2;
    HalfHeight := Height div 2;
    for Y := 0 to Height - 1 do
    begin
      TargetRun := Scanline[Y];
      SourceRun := Source.Scanline[Y];
      for X := 0 to Width - 1 do
      begin
        Color := SourceRun.Color and $FFFFFF;
        if UseColorKey and (Color = ColorKeyRef) then
          TargetRun.Alpha := 0
        else
        begin
          
          T := exp(-8 * Sqrt(Sqr((X - HalfWidth) / MaxDimension) + Sqr((Y - HalfHeight) / MaxDimension)));
          TargetRun.Alpha := Round(255 * T);
        end;
        Inc(SourceRun);
        Inc(TargetRun);
      end;
    end;
  end;
end;

function TVTDragImage.DragTo(P: TPoint; ForceRepaint: Boolean): Boolean;

var
  ScreenDC: HDC;
  DeltaX,
  DeltaY: Integer;
  
  RSamp1,
  RSamp2,       
  RDraw1,
  RDraw2,       
  RScroll,
  RClip: TRect; 

begin
  
  case FRestriction of
    dmrHorizontalOnly:
      begin
        DeltaX := FLastPosition.X - P.X;
        DeltaY := 0;
      end;
    dmrVerticalOnly:
      begin
        DeltaX := 0;
        DeltaY := FLastPosition.Y - P.Y;
      end;
  else 
    DeltaX := FLastPosition.X - P.X;
    DeltaY := FLastPosition.Y - P.Y;
  end;

  Result := (DeltaX <> 0) or (DeltaY <> 0) or ForceRepaint;
  if Result then
  begin
    if Visible then
    begin
      
      ScreenDC := GetDC(0);
      try
        if (Abs(DeltaX) >= FDragImage.Width) or (Abs(DeltaY) >= FDragImage.Height) or ForceRepaint then
        begin
          
          BitBlt(ScreenDC, FImagePosition.X, FImagePosition.Y, FBackImage.Width, FBackImage.Height,
            FBackImage.Canvas.Handle, 0, 0, SRCCOPY);

          if ForceRepaint then
            UpdateWindow(FOwner.Handle);

          Inc(FImagePosition.X, -DeltaX);
          Inc(FImagePosition.Y, -DeltaY);

          BitBlt(FBackImage.Canvas.Handle, 0, 0, FBackImage.Width, FBackImage.Height, ScreenDC, FImagePosition.X,
            FImagePosition.Y, SRCCOPY);
        end
        else
        begin
          
          FillDragRectangles(FDragImage.Width, FDragImage.Height, DeltaX, DeltaY, RClip, RScroll, RSamp1, RSamp2, RDraw1,
            RDraw2);

          with FBackImage.Canvas do
          begin
            
            if DeltaX = 0 then
            begin
              with TWithSafeRect(RDraw2) do
                BitBlt(ScreenDC, FImagePosition.X + Left, FImagePosition.Y + Top, Right, Bottom, Handle, Left, Top,
                  SRCCOPY);
            end
            else
            begin
              if DeltaY = 0 then
              begin
                with TWithSafeRect(RDraw1) do
                  BitBlt(ScreenDC, FImagePosition.X + Left, FImagePosition.Y + Top, Right, Bottom, Handle, Left, Top,
                    SRCCOPY);
              end
              else
              begin
                with TWithSafeRect(RDraw1) do
                  BitBlt(ScreenDC, FImagePosition.X + Left, FImagePosition.Y + Top, Right, Bottom, Handle, Left, Top,
                    SRCCOPY);
                with TWithSafeRect(RDraw2) do
                  BitBlt(ScreenDC, FImagePosition.X + Left, FImagePosition.Y + Top, Right, Bottom, Handle, Left, Top,
                    SRCCOPY);
              end;
            end;
            
            ScrollDC(Handle, DeltaX, DeltaY, RScroll, RClip, 0, nil);

            Inc(FImagePosition.X, -DeltaX);
            Inc(FImagePosition.Y, -DeltaY);
            
            if DeltaX = 0 then
            begin
              with TWithSafeRect(RSamp2) do
                BitBlt(Handle, Left, Top, Right, Bottom, ScreenDC, FImagePosition.X + Left, FImagePosition.Y + Top,
                  SRCCOPY);
            end
            else
              if DeltaY = 0 then
              begin
                with TWithSafeRect(RSamp1) do
                  BitBlt(Handle, Left, Top, Right, Bottom, ScreenDC, FImagePosition.X + Left, FImagePosition.Y + Top,
                    SRCCOPY);
              end
              else
              begin
                with TWithSafeRect(RSamp1) do
                  BitBlt(Handle, Left, Top, Right, Bottom, ScreenDC, FImagePosition.X + Left, FImagePosition.Y + Top,
                    SRCCOPY);
                with TWithSafeRect(RSamp2) do
                  BitBlt(Handle, Left, Top, Right, Bottom, ScreenDC, FImagePosition.X + Left, FImagePosition.Y + Top,
                    SRCCOPY);
              end;
          end;
        end;
        InternalShowDragImage(ScreenDC);
      finally
        ReleaseDC(0, ScreenDC);
      end;
    end;
    FLastPosition.X := P.X;
    FLastPosition.Y := P.Y;
  end;
end;

procedure TVTDragImage.EndDrag;

begin
  HideDragImage;
  FStates := FStates - [disInDrag, disPrepared];

  FBackImage.Free;
  FBackImage := nil;
  FDragImage.Free;
  FDragImage := nil;
  FAlphaImage.Free;
  FAlphaImage := nil;
end;

function TVTDragImage.GetDragImageRect: TRect;

begin
  if Visible then
  begin
    with FBackImage do
      Result := Rect(FImagePosition.X, FImagePosition.Y, FImagePosition.X + Width, FImagePosition.Y + Height);
  end
  else
    Result := Rect(0, 0, 0, 0);
end;

procedure TVTDragImage.HideDragImage;

var
  ScreenDC: HDC;

begin
  if Visible then
  begin
    Include(FStates, disHidden);
    ScreenDC := GetDC(0);
    try
      
      with FBackImage do
        BitBlt(ScreenDC, FImagePosition.X, FImagePosition.Y, Width, Height, Canvas.Handle, 0, 0, SRCCOPY);
    finally
      ReleaseDC(0, ScreenDC);
    end;
  end;
end;

procedure TVTDragImage.PrepareDrag(DragImage: TBitmap; ImagePosition, HotSpot: TPoint; const DataObject: IDataObject);

var
  Width,
  Height: Integer;
  DragSourceHelper: IDragSourceHelper;
  DragInfo: TSHDragImage;
  lDragSourceHelper2: IDragSourceHelper2;
  lNullPoint: TPoint;
begin
  Width := DragImage.Width;
  Height := DragImage.Height;
  
  if Assigned(DataObject) and Succeeded(CoCreateInstance(CLSID_DragDropHelper, nil, CLSCTX_INPROC_SERVER,
    IDragSourceHelper, DragSourceHelper)) then
  begin
    Include(FStates, disSystemSupport);
    lNullPoint := Point(0,0);
    if Supports(DragSourceHelper, IDragSourceHelper2, lDragSourceHelper2) then
      lDragSourceHelper2.SetFlags(DSH_ALLOWDROPDESCRIPTIONTEXT);
    
    StandardOLEFormat.cfFormat := CF_HDROP;
    if not Succeeded(DataObject.QueryGetData(StandardOLEFormat)) or not Succeeded(DragSourceHelper.InitializeFromWindow(0, lNullPoint, DataObject)) then begin
      
      DragInfo.sizeDragImage.cx := Width;
      DragInfo.sizeDragImage.cy := Height;
      DragInfo.ptOffset.x := Width div 2;
      DragInfo.ptOffset.y := Height div 2;
      DragInfo.hbmpDragImage := CopyImage(DragImage.Handle, IMAGE_BITMAP, Width, Height, LR_COPYRETURNORG);
      DragInfo.crColorKey := ColorToRGB(FColorKey);
      if not Succeeded(DragSourceHelper.InitializeFromBitmap(@DragInfo, DataObject)) then
      begin
        DeleteObject(DragInfo.hbmpDragImage);
        Exclude(FStates, disSystemSupport);
      end;
    end;
  end
  else
    Exclude(FStates, disSystemSupport);

  if MMXAvailable and not (disSystemSupport in FStates) then
  begin
    FLastPosition := HotSpot;

    FDragImage := TBitmap.Create;
    FDragImage.PixelFormat := pf32Bit;
    FDragImage.Width := Width;
    FDragImage.Height := Height;

    FAlphaImage := TBitmap.Create;
    FAlphaImage.PixelFormat := pf32Bit;
    FAlphaImage.Width := Width;
    FAlphaImage.Height := Height;

    FBackImage := TBitmap.Create;
    FBackImage.PixelFormat := pf32Bit;
    FBackImage.Width := Width;
    FBackImage.Height := Height;
    
    if FPreBlendBias = 0 then
      with FDragImage do
        BitBlt(Canvas.Handle, 0, 0, Width, Height, DragImage.Canvas.Handle, 0, 0, SRCCOPY)
    else
      AlphaBlend(DragImage.Canvas.Handle, FDragImage.Canvas.Handle, Rect(0, 0, Width, Height), Point(0, 0),
        bmConstantAlpha, 255, FPreBlendBias);
    
    MakeAlphaChannel(DragImage, FDragImage);

    FImagePosition := ImagePosition;
    
    FStates := FStates + [disInDrag, disHidden, disPrepared];
  end;
end;

procedure TVTDragImage.RecaptureBackground(Tree: TBaseVirtualTree; R: TRect; VisibleRegion: HRGN;
  CaptureNCArea, ReshowDragImage: Boolean);

var
  DragRect,
  ClipRect: TRect;
  PaintTarget: TPoint;
  PaintOptions: TVTInternalPaintOptions;
  ScreenDC: HDC;

begin
  
  if Visible then
  begin
    
    MapWindowPoints(Tree.Handle, 0, R, 2);
    DragRect := GetDragImageRect;
    IntersectRect(R, R, DragRect);

    OffsetRgn(VisibleRegion, -DragRect.Left, -DragRect.Top);
    
    PaintTarget.X := R.Left - DragRect.Left;
    PaintTarget.Y := R.Top - DragRect.Top;
    
    MapWindowPoints(0, Tree.Handle, R, 2);
    OffsetRect(R, -Tree.FOffsetX, -Tree.FOffsetY);
    
    PaintOptions := [poBackground, poColumnColor, poDrawFocusRect, poDrawDropMark, poDrawSelection, poGridLines];
    with FBackImage do
    begin
      ClipRect.TopLeft := PaintTarget;
      ClipRect.Right := ClipRect.Left + R.Right - R.Left;
      ClipRect.Bottom := ClipRect.Top + R.Bottom - R.Top;
      ClipCanvas(Canvas, ClipRect, VisibleRegion);
      Tree.PaintTree(Canvas, R, PaintTarget, PaintOptions);

      if CaptureNCArea then
      begin
        
        SelectClipRgn(Canvas.Handle, VisibleRegion);
        
        GetWindowRect(Tree.Handle, ClipRect);
        SetCanvasOrigin(Canvas, DragRect.Left - ClipRect.Left, DragRect.Top - ClipRect.Top);
        Tree.Perform(WM_PRINT, WPARAM(Canvas.Handle), PRF_NONCLIENT);
        SetCanvasOrigin(Canvas, 0, 0);
      end;
      SelectClipRgn(Canvas.Handle, 0);

      if ReshowDragImage then
      begin
        GDIFlush;
        ScreenDC := GetDC(0);
        try
          InternalShowDragImage(ScreenDC);
        finally
          ReleaseDC(0, ScreenDC);
        end;
      end;
    end;
  end;
end;

procedure TVTDragImage.ShowDragImage;

var
  ScreenDC: HDC;

begin
  if FStates * [disInDrag, disHidden, disPrepared, disSystemSupport] = [disInDrag, disHidden, disPrepared] then
  begin
    Exclude(FStates, disHidden);

    GDIFlush;
    ScreenDC := GetDC(0);
    try
      BitBlt(FBackImage.Canvas.Handle, 0, 0, FBackImage.Width, FBackImage.Height, ScreenDC, FImagePosition.X,
        FImagePosition.Y, SRCCOPY);

      InternalShowDragImage(ScreenDC);
    finally
      ReleaseDC(0, ScreenDC);
    end;
  end;
end;

function TVTDragImage.WillMove(P: TPoint): Boolean;

var
  DeltaX,
  DeltaY: Integer;

begin
  Result := Visible;
  if Result then
  begin
    
    case FRestriction of
      dmrHorizontalOnly:
        begin
          DeltaX := FLastPosition.X - P.X;
          DeltaY := 0;
        end;
      dmrVerticalOnly:
        begin
          DeltaX := 0;
          DeltaY := FLastPosition.Y - P.Y;
        end;
    else 
      DeltaX := FLastPosition.X - P.X;
      DeltaY := FLastPosition.Y - P.Y;
    end;

    Result := (DeltaX <> 0) or (DeltaY <> 0);
  end;
end;

function TVTVirtualNodeEnumerator.GetCurrent: PVirtualNode;

begin
  Result := FNode;
end;

function TVTVirtualNodeEnumerator.MoveNext: Boolean;

begin
  Result := FCanModeNext;
  if Result then
  begin
    FNode := FEnumeration.GetNext(FNode);
    Result := FNode <> nil;
    FCanModeNext := Result;
  end;
end;

function TVTVirtualNodeEnumeration.GetEnumerator: TVTVirtualNodeEnumerator;

begin
  {$if CompilerVersion >= 18}
  {$else}
  Result := TVTVirtualNodeEnumerator.Create;
  {$ifend}
  Result.FNode := nil;
  Result.FCanModeNext := True;
  Result.FEnumeration := @Self;
end;

function TVTVirtualNodeEnumeration.GetNext(Node: PVirtualNode): PVirtualNode;
begin
  case FMode of
    vneAll:
      if Node = nil then
        Result := FTree.GetFirst(FConsiderChildrenAbove)
      else
        Result := FTree.GetNext(Node, FConsiderChildrenAbove);

    vneChecked:
      if Node = nil then
        Result := FTree.GetFirstChecked(FState, FConsiderChildrenAbove)
      else
        Result := FTree.GetNextChecked(Node, FState, FConsiderChildrenAbove);

    vneChild:
      if Node = nil then
        Result := FTree.GetFirstChild(FNode)
      else
        Result := FTree.GetNextSibling(Node);

    vneCutCopy:
      if Node = nil then
        Result := FTree.GetFirstCutCopy(FConsiderChildrenAbove)
      else
        Result := FTree.GetNextCutCopy(Node, FConsiderChildrenAbove);

    vneInitialized:
      if Node = nil then
        Result := FTree.GetFirstInitialized(FConsiderChildrenAbove)
      else
        Result := FTree.GetNextInitialized(Node, FConsiderChildrenAbove);

    vneLeaf:
      if Node = nil then
        Result := FTree.GetFirstLeaf
      else
        Result := FTree.GetNextLeaf(Node);

    vneLevel:
      if Node = nil then
        Result := FTree.GetFirstLevel(FNodeLevel)
      else
        Result := FTree.GetNextLevel(Node, FNodeLevel);

    vneNoInit:
      if Node = nil then
        Result := FTree.GetFirstNoInit(FConsiderChildrenAbove)
      else
        Result := FTree.GetNextNoInit(Node, FConsiderChildrenAbove);

    vneSelected:
      if Node = nil then
        Result := FTree.GetFirstSelected(FConsiderChildrenAbove)
      else
        Result := FTree.GetNextSelected(Node, FConsiderChildrenAbove);

    vneVisible:
      begin
        if Node = nil then
        begin
          Result := FTree.GetFirstVisible(FNode, FConsiderChildrenAbove, FIncludeFiltered);
          if FIncludeFiltered or not FTree.IsEffectivelyFiltered[Result] then
            Exit;
        end;
        repeat
          Result := FTree.GetNextVisible(Node);
        until not Assigned(Result) or FIncludeFiltered or not FTree.IsEffectivelyFiltered[Result];
      end;

    vneVisibleChild:
      if Node = nil then
        Result := FTree.GetFirstVisibleChild(FNode, FIncludeFiltered)
      else
        Result := FTree.GetNextVisibleSibling(Node, FIncludeFiltered);

    vneVisibleNoInitChild:
      if Node = nil then
        Result := FTree.GetFirstVisibleChildNoInit(FNode, FIncludeFiltered)
      else
        Result := FTree.GetNextVisibleSiblingNoInit(Node, FIncludeFiltered);

    vneVisibleNoInit:
      begin
        if Node = nil then
        begin
          Result := FTree.GetFirstVisibleNoInit(FNode, FConsiderChildrenAbove, FIncludeFiltered);
          if FIncludeFiltered or not FTree.IsEffectivelyFiltered[Result] then
            Exit;
        end;
        repeat
          Result := FTree.GetNextVisibleNoInit(Node, FConsiderChildrenAbove);
        until not Assigned(Result) or FIncludeFiltered or not FTree.IsEffectivelyFiltered[Result];
      end;
  else
    Result := nil;
  end;
end;

constructor TVirtualTreeColumn.Create(Collection: TCollection);

begin
  FMinWidth := 10;
  FMaxWidth := 10000;
  FImageIndex := -1;
  FMargin := 4;
  FSpacing := 3;
  FText := '';
  FOptions := DefaultColumnOptions;
  FAlignment := taLeftJustify;
  FBidiMode := bdLeftToRight;
  FColor := clWindow;
  FLayout := blGlyphLeft;
  FBonusPixel := False;
  FCaptionAlignment := taLeftJustify;
  FCheckType := ctCheckBox;
  FCheckState := csUncheckedNormal;
  FCheckBox := False;
  FHasImage := False;
  fDefaultSortDirection := sdAscending;

  inherited Create(Collection);

  FWidth := Owner.FDefaultWidth;
  FLastWidth := Owner.FDefaultWidth;
  FPosition := Owner.Count - 1;
  
  ParentBiDiModeChanged;
  ParentColorChanged;
end;

destructor TVirtualTreeColumn.Destroy;

var
  I: Integer;

  procedure AdjustColumnIndex(var ColumnIndex: TColumnIndex);

  begin
    if Index = ColumnIndex then
      ColumnIndex := NoColumn
    else
      if Index < ColumnIndex then
        Dec(ColumnIndex);
  end;

begin
  
  with Owner do
  begin
    
    if not FClearing then
    begin
      Header.Treeview.CancelEditNode;
      IndexChanged(Index, -1);

      AdjustColumnIndex(FHoverIndex);
      AdjustColumnIndex(FDownIndex);
      AdjustColumnIndex(FTrackIndex);
      AdjustColumnIndex(FClickIndex);

      with Header do
      begin
        AdjustColumnIndex(FAutoSizeIndex);
        if Index = FMainColumn then
        begin
          
          FMainColumn := NoColumn;
          for I := 0 to Count - 1 do
            if I <> Index then
            begin
              FMainColumn := I;
              Break;
            end;
        end;
        AdjustColumnIndex(FSortColumn);
      end;
    end;
  end;

  inherited;
end;

function TVirtualTreeColumn.GetCaptionAlignment: TAlignment;

begin
  if coUseCaptionAlignment in FOptions then
    Result := FCaptionAlignment
  else
    Result := FAlignment;
end;

function TVirtualTreeColumn.GetLeft: Integer;

begin
  Result := FLeft;
  if [coVisible, coFixed] * FOptions <> [coVisible, coFixed] then
    Dec(Result, Owner.Header.Treeview.FEffectiveOffsetX);
end;

function TVirtualTreeColumn.IsBiDiModeStored: Boolean;

begin
  Result := not (coParentBiDiMode in FOptions);
end;

function TVirtualTreeColumn.IsCaptionAlignmentStored: Boolean;

begin
  Result := coUseCaptionAlignment in FOptions;
end;

function TVirtualTreeColumn.IsColorStored: Boolean;

begin
  Result := not (coParentColor in FOptions);
end;

procedure TVirtualTreeColumn.SetAlignment(const Value: TAlignment);

begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Changed(False);
    
    Owner.Header.TreeView.Invalidate;
  end;
end;

procedure TVirtualTreeColumn.SetBiDiMode(Value: TBiDiMode);

begin
  if Value <> FBiDiMode then
  begin
    FBiDiMode := Value;
    Exclude(FOptions, coParentBiDiMode);
    Changed(False);
    
    Owner.Header.TreeView.Invalidate;
  end;
end;

procedure TVirtualTreeColumn.SetCaptionAlignment(const Value: TAlignment);

begin
  if not (coUseCaptionAlignment in FOptions) or (FCaptionAlignment <> Value) then
  begin
    FCaptionAlignment := Value;
    Include(FOptions, coUseCaptionAlignment);
    
    Owner.Header.Invalidate(Self);
  end;
end;

procedure TVirtualTreeColumn.SetColor(const Value: TColor);

begin
  if FColor <> Value then
  begin
    FColor := Value;
    Exclude(FOptions, coParentColor);
    Changed(False);
    Owner.Header.TreeView.Invalidate;
  end;
end;

procedure TVirtualTreeColumn.SetCheckBox(Value: boolean);

begin
  if Value <> FCheckBox then
  begin
    FCheckBox := Value;
    if Value and (csDesigning in Owner.Header.Treeview.ComponentState) then
      Owner.Header.Options := Owner.Header.Options + [hoShowImages];
    Changed(False);
  end;
end;

procedure TVirtualTreeColumn.SetCheckState(Value: TCheckState);

begin
  if Value <> FCheckState then
  begin
    FCheckState := Value;
    Changed(False);
  end;
end;

procedure TVirtualTreeColumn.SetCheckType(Value: TCheckType);

begin
  if Value <> FCheckType then
  begin
    FCheckType := Value;
    Changed(False);
  end;
end;

procedure TVirtualTreeColumn.SetImageIndex(Value: TImageIndex);

begin
  if Value <> FImageIndex then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;

procedure TVirtualTreeColumn.SetLayout(Value: TVTHeaderColumnLayout);

begin
  if FLayout <> Value then
  begin
    FLayout := Value;
    Changed(False);
  end;
end;

procedure TVirtualTreeColumn.SetMargin(Value: Integer);

begin
  
  if Value < 0 then
    Value := 4;
  if FMargin <> Value then
  begin
    FMargin := Value;
    Changed(False);
  end;
end;

procedure TVirtualTreeColumn.SetMaxWidth(Value: Integer);

begin
  if Value < FMinWidth then
    Value := FMinWidth;
  FMaxWidth := Value;
  SetWidth(FWidth);
end;

procedure TVirtualTreeColumn.SetMinWidth(Value: Integer);

begin
  if Value < 0 then
    Value := 0;
  if Value > FMaxWidth then
    Value := FMaxWidth;
  FMinWidth := Value;
  SetWidth(FWidth);
end;

procedure TVirtualTreeColumn.SetOptions(Value: TVTColumnOptions);

var
  ToBeSet,
  ToBeCleared: TVTColumnOptions;
  VisibleChanged,
  ColorChanged: Boolean;

begin
  if FOptions <> Value then
  begin
    ToBeCleared := FOptions - Value;
    ToBeSet := Value - FOptions;

    FOptions := Value;

    VisibleChanged := coVisible in (ToBeSet + ToBeCleared);
    ColorChanged := coParentColor in ToBeSet;

    if coParentBidiMode in ToBeSet then
      ParentBiDiModeChanged;
    if ColorChanged then
      ParentColorChanged;

    if coAutoSpring in ToBeSet then
      FSpringRest := 0;

    if ((coFixed in ToBeSet) or (coFixed in ToBeCleared)) and (coVisible in FOptions) then
      Owner.Header.RescaleHeader;

    Changed(False);
    
    with Owner, Header.Treeview do
      if not (csLoading in ComponentState) and (VisibleChanged or ColorChanged) and (UpdateCount = 0) and
        HandleAllocated then
      begin
        Invalidate;
        if VisibleChanged then
          UpdateHorizontalScrollBar(False);
      end;
  end;
end;

procedure TVirtualTreeColumn.SetPosition(Value: TColumnPosition);

var
  Temp: TColumnIndex;

begin
  if csLoading in Owner.Header.Treeview.ComponentState then
    
    FPosition := Value
  else
  begin
    if Value >= TColumnPosition(Collection.Count) then
      Value := Collection.Count - 1;
    if FPosition <> Value then
    begin
      with Owner do
      begin
        InitializePositionArray;
        Header.Treeview.CancelEditNode;
        AdjustPosition(Self, Value);
        Self.Changed(False);
        
        with Header do
        begin
          if (UpdateCount = 0) and Treeview.HandleAllocated then
          begin
            Invalidate(Self);
            Treeview.Invalidate;
          end;
        end;
      end;
      
      if (coFixed in FOptions) and (FPosition > 0) then
        Temp := Owner.ColumnFromPosition(FPosition - 1)
      else
        Temp := Owner.ColumnFromPosition(FPosition + 1);

      if Temp <> NoColumn then
      begin
        if coFixed in Owner[Temp].Options then
          Options := Options + [coFixed]
        else
          Options := Options - [coFixed]
      end;
    end;
  end;
end;

procedure TVirtualTreeColumn.SetSpacing(Value: Integer);

begin
  if FSpacing <> Value then
  begin
    FSpacing := Value;
    Changed(False);
  end;
end;

procedure TVirtualTreeColumn.SetStyle(Value: TVirtualTreeColumnStyle);

begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    Changed(False);
  end;
end;

procedure TVirtualTreeColumn.SetText(const Value: UnicodeString);

begin
  if FText <> Value then
  begin
    FText := Value;
    FCaptionText := '';
    Changed(False);
  end;
end;

procedure TVirtualTreeColumn.SetWidth(Value: Integer);

var
  EffectiveMaxWidth,
  EffectiveMinWidth,
  TotalFixedMaxWidth,
  TotalFixedMinWidth: Integer;
  I: TColumnIndex;

begin
  if not (hsScaling in Owner.FHeader.FStates) then
    if ([coVisible, coFixed] * FOptions = [coVisible, coFixed]) then
    begin
      with Owner, FHeader, FFixedAreaConstraints, TreeView do
      begin
        TotalFixedMinWidth := 0;
        TotalFixedMaxWidth := 0;
        for I := 0 to FColumns.Count - 1 do
          if ([coVisible, coFixed] * FColumns[I].FOptions = [coVisible, coFixed]) then
          begin
            Inc(TotalFixedMaxWidth, FColumns[I].FMaxWidth);
            Inc(TotalFixedMinWidth, FColumns[I].FMinWidth);
          end;
        
        TotalFixedMinWidth := IfThen(FMaxWidthPercent > 0,
                                     Min((ClientWidth * FMaxWidthPercent) div 100, TotalFixedMinWidth),
                                     TotalFixedMinWidth);
        TotalFixedMaxWidth := IfThen(FMinWidthPercent > 0,
                                     Max((ClientWidth * FMinWidthPercent) div 100, TotalFixedMaxWidth),
                                     TotalFixedMaxWidth);

        EffectiveMaxWidth := Min(TotalFixedMaxWidth - (GetVisibleFixedWidth - Self.FWidth), FMaxWidth);
        EffectiveMinWidth := Max(TotalFixedMinWidth - (GetVisibleFixedWidth - Self.FWidth), FMinWidth);
        Value := Min(Max(Value, EffectiveMinWidth), EffectiveMaxWidth);

        if FMinWidthPercent > 0 then
          Value := Max((ClientWidth * FMinWidthPercent) div 100 - GetVisibleFixedWidth + Self.FWidth, Value);
        if FMaxWidthPercent > 0 then
          Value := Min((ClientWidth * FMaxWidthPercent) div 100 - GetVisibleFixedWidth + Self.FWidth, Value);
      end;
    end
    else
      Value := Min(Max(Value, FMinWidth), FMaxWidth);

  if FWidth <> Value then
  begin
    FLastWidth := FWidth;
    if not (hsResizing in Owner.Header.States) then
      FBonusPixel := False;
    with Owner, Header do
    begin
      if not (hoAutoResize in FOptions) or (Index <> FAutoSizeIndex) then
      begin
        FWidth := Value;
        UpdatePositions;
      end;
      if not (csLoading in Treeview.ComponentState) and (UpdateCount = 0) then
      begin
        if hoAutoResize in FOptions then
          AdjustAutoSize(Index);
        Treeview.DoColumnResize(Index);
      end;
    end;
  end;
end;

procedure TVirtualTreeColumn.ComputeHeaderLayout(DC: HDC; Client: TRect; UseHeaderGlyph, UseSortGlyph: Boolean;
  var HeaderGlyphPos, SortGlyphPos: TPoint; var SortGlyphSize: TSize; var TextBounds: TRect; DrawFormat: Cardinal;
  CalculateTextRect: Boolean = False);

var
  TextSize: TSize;
  TextPos,
  ClientSize,
  HeaderGlyphSize: TPoint;
  CurrentAlignment: TAlignment;
  MinLeft,
  MaxRight,
  TextSpacing: Integer;
  UseText: Boolean;
  R: TRect;
  Theme: HTHEME;

begin
  UseText := Length(FText) > 0;
  
  if not (UseText or UseHeaderGlyph or UseSortGlyph) then
    Exit;

  CurrentAlignment := CaptionAlignment;
  if FBidiMode <> bdLeftToRight then
    ChangeBiDiModeAlignment(CurrentAlignment);
  
  ClientSize := Point(Client.Right - Client.Left, Client.Bottom - Client.Top);
  with Owner, Header do
  begin
    if UseHeaderGlyph then
      if not FCheckBox then
        HeaderGlyphSize := Point(FImages.Width, FImages.Height)
      else
        with TBaseVirtualTree.GetCheckImageListFor(FHeader.Treeview.CheckImageKind) do
          HeaderGlyphSize := Point(Width, Height)
    else
      HeaderGlyphSize := Point(0, 0);
    if UseSortGlyph then
    begin
      if tsUseExplorerTheme in FHeader.Treeview.FStates then
      begin
        R := Rect(0, 0, 100, 100);
        Theme := OpenThemeData(FHeader.Treeview.Handle, 'HEADER');
        GetThemePartSize(Theme, DC, HP_HEADERSORTARROW, HSAS_SORTEDUP, @R, TS_TRUE, SortGlyphSize);
        CloseThemeData(Theme);
      end
      else
      begin
        SortGlyphSize.cx := UtilityImages.Width;
        SortGlyphSize.cy := UtilityImages.Height;
      end;
      
      SortGlyphPos.Y := (ClientSize.Y - SortGlyphSize.cy) div 2;
    end
    else
    begin
      SortGlyphSize.cx := 0;
      SortGlyphSize.cy := 0;
    end;
  end;

  if UseText then
  begin
    if not (coWrapCaption in FOptions) then
    begin
      FCaptionText := FText;
      GetTextExtentPoint32W(DC, PWideChar(FText), Length(FText), TextSize);
      Inc(TextSize.cx, 2);
      TextBounds := Rect(0, 0, TextSize.cx, TextSize.cy);
    end
    else
    begin
      R := Client;
      if FCaptionText = '' then
        FCaptionText := WrapString(DC, FText, R, DT_RTLREADING and DrawFormat <> 0, DrawFormat);

      GetStringDrawRect(DC, FCaptionText, R, DrawFormat);
      TextSize.cx := Client.Right - Client.Left;
      TextSize.cy := R.Bottom - R.Top;
      TextBounds  := Rect(0, 0, TextSize.cx, TextSize.cy);
    end;
    TextSpacing := FSpacing;
  end
  else
  begin
    TextSpacing := 0;
    TextSize.cx := 0;
    TextSize.cy := 0;
  end;
  
  if UseSortGlyph and not (UseText or UseHeaderGlyph) then
  begin
    
    SortGlyphPos := Point((ClientSize.X - SortGlyphSize.cx) div 2, (ClientSize.Y - SortGlyphSize.cy) div 2);
  end
  else
  begin
    
    if (Layout in [blGlyphLeft, blGlyphRight]) or not UseHeaderGlyph then
    begin
      HeaderGlyphPos.Y := (ClientSize.Y - HeaderGlyphSize.Y) div 2;
      
      TextPos.Y := Max(-5, (ClientSize.Y - TextSize.cy) div 2);
    end
    else
    begin
      if Layout = blGlyphTop then
      begin
        HeaderGlyphPos.Y := (ClientSize.Y - HeaderGlyphSize.Y - TextSize.cy - TextSpacing) div 2;
        TextPos.Y := HeaderGlyphPos.Y + HeaderGlyphSize.Y + TextSpacing;
      end
      else
      begin
        TextPos.Y := (ClientSize.Y - HeaderGlyphSize.Y - TextSize.cy - TextSpacing) div 2;
        HeaderGlyphPos.Y := TextPos.Y + TextSize.cy + TextSpacing;
      end;
    end;
    
    case CurrentAlignment of
      taLeftJustify:
        begin
          MinLeft := FMargin;
          if UseSortGlyph and (FBidiMode <> bdLeftToRight) then
          begin
            
            SortGlyphPos.X := MinLeft;
            Inc(MinLeft, SortGlyphSize.cx + FSpacing);
          end;
          if Layout in [blGlyphTop, blGlyphBottom] then
          begin
            
            TextPos.X := MinLeft;
            if UseHeaderGlyph then
            begin
              HeaderGlyphPos.X := (ClientSize.X - HeaderGlyphSize.X) div 2;
              if HeaderGlyphPos.X < MinLeft then
                HeaderGlyphPos.X := MinLeft;
              MinLeft := Max(TextPos.X + TextSize.cx + TextSpacing, HeaderGlyphPos.X + HeaderGlyphSize.X + FSpacing);
            end
            else
              MinLeft := TextPos.X + TextSize.cx + TextSpacing;
          end
          else
          begin
            
            if UseHeaderGlyph and (Layout = blGlyphLeft) then
            begin
              HeaderGlyphPos.X := MinLeft;
              Inc(MinLeft, HeaderGlyphSize.X + FSpacing);
            end;
            TextPos.X := MinLeft;
            Inc(MinLeft, TextSize.cx + TextSpacing);
            if UseHeaderGlyph and (Layout = blGlyphRight) then
            begin
              HeaderGlyphPos.X := MinLeft;
              Inc(MinLeft, HeaderGlyphSize.X + FSpacing);
            end;
          end;
          if UseSortGlyph and (FBidiMode = bdLeftToRight) then
            SortGlyphPos.X := MinLeft;
        end;
      taCenter:
        begin
          if Layout in [blGlyphTop, blGlyphBottom] then
          begin
            HeaderGlyphPos.X := (ClientSize.X - HeaderGlyphSize.X) div 2;
            TextPos.X := (ClientSize.X - TextSize.cx) div 2;
            if UseSortGlyph then
              Dec(TextPos.X, SortGlyphSize.cx div 2);
          end
          else
          begin
            MinLeft := (ClientSize.X - HeaderGlyphSize.X - TextSpacing - TextSize.cx) div 2;
            if UseHeaderGlyph and (Layout = blGlyphLeft) then
            begin
              HeaderGlyphPos.X := MinLeft;
              Inc(MinLeft, HeaderGlyphSize.X + TextSpacing);
            end;
            TextPos.X := MinLeft;
            Inc(MinLeft, TextSize.cx + TextSpacing);
            if UseHeaderGlyph and (Layout = blGlyphRight) then
              HeaderGlyphPos.X := MinLeft;
          end;
          if UseHeaderGlyph then
          begin
            MinLeft := Min(HeaderGlyphPos.X, TextPos.X);
            MaxRight := Max(HeaderGlyphPos.X + HeaderGlyphSize.X, TextPos.X + TextSize.cx);
          end
          else
          begin
            MinLeft := TextPos.X;
            MaxRight := TextPos.X + TextSize.cx;
          end;
          
          if UseSortGlyph then
            if FBidiMode = bdLeftToRight then
            begin
              
              SortGlyphPos.X := MaxRight + FSpacing;
            end
            else
            begin
              
              SortGlyphPos.X := MinLeft - FSpacing - SortGlyphSize.cx;
            end;
        end;
    else
      
      MaxRight := ClientSize.X - FMargin;
      if UseSortGlyph and (FBidiMode = bdLeftToRight) then
      begin
        
        Dec(MaxRight, SortGlyphSize.cx);
        SortGlyphPos.X := MaxRight;
        Dec(MaxRight, FSpacing);
      end;
      if Layout in [blGlyphTop, blGlyphBottom] then
      begin
        TextPos.X := MaxRight - TextSize.cx;
        if UseHeaderGlyph then
        begin
          HeaderGlyphPos.X := (ClientSize.X - HeaderGlyphSize.X) div 2;
          if HeaderGlyphPos.X + HeaderGlyphSize.X + FSpacing > MaxRight then
            HeaderGlyphPos.X := MaxRight - HeaderGlyphSize.X - FSpacing;
          MaxRight := Min(TextPos.X - TextSpacing, HeaderGlyphPos.X - FSpacing);
        end
        else
          MaxRight := TextPos.X - TextSpacing;
      end
      else
      begin
        
        if UseHeaderGlyph and (Layout = blGlyphRight) then
        begin
          HeaderGlyphPos.X := MaxRight -  HeaderGlyphSize.X;
          MaxRight := HeaderGlyphPos.X - FSpacing;
        end;
        TextPos.X := MaxRight - TextSize.cx;
        MaxRight := TextPos.X - TextSpacing;
        if UseHeaderGlyph and (Layout = blGlyphLeft) then
        begin
          HeaderGlyphPos.X := MaxRight - HeaderGlyphSize.X;
          MaxRight := HeaderGlyphPos.X - FSpacing;
        end;
      end;
      if UseSortGlyph and (FBidiMode <> bdLeftToRight) then
        SortGlyphPos.X := MaxRight - SortGlyphSize.cx;
    end;
  end;
  
  MinLeft := FMargin;
  MaxRight := ClientSize.X - FMargin;
  if UseSortGlyph then
  begin
    if FBidiMode = bdLeftToRight then
    begin
      
      if SortGlyphPos.X + SortGlyphSize.cx > MaxRight then
        SortGlyphPos.X := MaxRight - SortGlyphSize.cx;
      MaxRight := SortGlyphPos.X - FSpacing;
    end;
    
    if SortGlyphPos.X < MinLeft then
      SortGlyphPos.X := MinLeft;
    
    if FBidiMode <> bdLeftToRight then
      MinLeft := SortGlyphPos.X + SortGlyphSize.cx + FSpacing;
    
    Inc(SortGlyphPos.X, Client.Left);
    Inc(SortGlyphPos.Y, Client.Top);
  end;
  if UseHeaderGlyph then
  begin
    if HeaderGlyphPos.X + HeaderGlyphSize.X > MaxRight then
      HeaderGlyphPos.X := MaxRight - HeaderGlyphSize.X;
    if Layout = blGlyphRight then
      MaxRight := HeaderGlyphPos.X - FSpacing;
    if HeaderGlyphPos.X < MinLeft then
      HeaderGlyphPos.X := MinLeft;
    if Layout = blGlyphLeft then
      MinLeft := HeaderGlyphPos.X + HeaderGlyphSize.X + FSpacing;
    if FCheckBox and (Owner.Header.MainColumn = Self.Index) then
      Dec(HeaderGlyphPos.X, 2 + 2 * Integer(toShowRoot in Owner.FHeader.Treeview.TreeOptions.FPaintOptions))
    else
      if Owner.Header.MainColumn <> Self.Index then
        Dec(HeaderGlyphPos.X, 2);
    
    Inc(HeaderGlyphPos.X, Client.Left);
    Inc(HeaderGlyphPos.Y, Client.Top);
  end;
  if UseText then
  begin
    if TextPos.X < MinLeft then
      TextPos.X := MinLeft;
    OffsetRect(TextBounds, TextPos.X, TextPos.Y);
    if TextBounds.Right > MaxRight then
      TextBounds.Right := MaxRight;
    OffsetRect(TextBounds, Client.Left, Client.Top);

    if coWrapCaption in FOptions then
    begin
      
      R := TextBounds;
      FCaptionText := WrapString(DC, FText, R, DT_RTLREADING and DrawFormat <> 0, DrawFormat);
      GetStringDrawRect(DC, FCaptionText, R, DrawFormat);
    end;
  end;
end;

procedure TVirtualTreeColumn.DefineProperties(Filer: TFiler);

begin
  inherited;
  
  Filer.DefineProperty('WideText', ReadText, WriteText, FText <> '');
  Filer.DefineProperty('WideHint', ReadHint, WriteHint, FHint <> '');
end;

procedure TVirtualTreeColumn.GetAbsoluteBounds(var Left, Right: Integer);

begin
  Left := FLeft;
  Right := FLeft + FWidth;
end;

function TVirtualTreeColumn.GetDisplayName: string;

var
  I: Integer;

begin
  
  I := 1;
  while I <= Length(FText) do
  begin
    if Ord(FText[I]) > 255 then
      Break;
    Inc(I);
  end;

  if I > Length(FText) then
    Result := FText 
  else
    Result := Format('Column %d', [Index]);
end;

function TVirtualTreeColumn.GetOwner: TVirtualTreeColumns;

begin
  Result := Collection as TVirtualTreeColumns;
end;

procedure TVirtualTreeColumn.ReadText(Reader: TReader);

begin
  case Reader.NextValue of
    vaLString, vaString:
      SetText(Reader.ReadString);
  else
    SetText(Reader.{$if CompilerVersion >= 23}ReadString{$else}ReadWideString{$ifend});
  end;
end;

procedure TVirtualTreeColumn.ReadHint(Reader: TReader);

begin
  case Reader.NextValue of
    vaLString, vaString:
      FHint := Reader.ReadString;
  else
    FHint := Reader.{$if CompilerVersion >= 23}ReadString{$else}ReadWideString{$ifend};
  end;
end;

procedure TVirtualTreeColumn.WriteHint(Writer: TWriter);

begin
  Writer.{$IF CompilerVersion >= 20}WriteString{$else}WriteWideString{$ifend}(FHint);
end;

procedure TVirtualTreeColumn.WriteText(Writer: TWriter);

begin
  Writer.{$IF CompilerVersion >= 20}WriteString{$else}WriteWideString{$ifend}(FText);
end;

procedure TVirtualTreeColumn.Assign(Source: TPersistent);

var
  OldOptions: TVTColumnOptions;

begin
  if Source is TVirtualTreeColumn then
  begin
    OldOptions := FOptions;
    FOptions := [];

    BiDiMode := TVirtualTreeColumn(Source).BiDiMode;
    ImageIndex := TVirtualTreeColumn(Source).ImageIndex;
    Layout := TVirtualTreeColumn(Source).Layout;
    Margin := TVirtualTreeColumn(Source).Margin;
    MaxWidth := TVirtualTreeColumn(Source).MaxWidth;
    MinWidth := TVirtualTreeColumn(Source).MinWidth;
    Position := TVirtualTreeColumn(Source).Position;
    Spacing := TVirtualTreeColumn(Source).Spacing;
    Style := TVirtualTreeColumn(Source).Style;
    Text := TVirtualTreeColumn(Source).Text;
    Hint := TVirtualTreeColumn(Source).Hint;
    Width := TVirtualTreeColumn(Source).Width;
    Alignment := TVirtualTreeColumn(Source).Alignment;
    CaptionAlignment := TVirtualTreeColumn(Source).CaptionAlignment;
    Color := TVirtualTreeColumn(Source).Color;
    Tag := TVirtualTreeColumn(Source).Tag;
    
    FOptions := OldOptions;
    Options := TVirtualTreeColumn(Source).Options;

    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TVirtualTreeColumn.Equals(OtherColumnObj: TObject): Boolean;
var
 OtherColumn : TVirtualTreeColumn;
begin
  if OtherColumnObj is TVirtualTreeColumn then
  begin
    OtherColumn :=  TVirtualTreeColumn (OtherColumnObj);
    Result := (BiDiMode = OtherColumn.BiDiMode) and
      (ImageIndex = OtherColumn.ImageIndex) and
      (Layout = OtherColumn.Layout) and
      (Margin = OtherColumn.Margin) and
      (MaxWidth = OtherColumn.MaxWidth) and
      (MinWidth = OtherColumn.MinWidth) and
      (Position = OtherColumn.Position) and
      (Spacing = OtherColumn.Spacing) and
      (Style = OtherColumn.Style) and
      (Text = OtherColumn.Text) and
      (Hint = OtherColumn.Hint) and
      (Width = OtherColumn.Width) and
      (Alignment = OtherColumn.Alignment) and
      (CaptionAlignment = OtherColumn.CaptionAlignment) and
      (Color = OtherColumn.Color) and
      (Tag = OtherColumn.Tag) and
      (Options = OtherColumn.Options)
  end
  else
    Result := False
end;

function TVirtualTreeColumn.GetRect: TRect;

begin
  with TVirtualTreeColumns(GetOwner).FHeader do
    Result := Treeview.FHeaderRect;
  Inc(Result.Left, FLeft);
  Result.Right := Result.Left + FWidth;
end;

procedure TVirtualTreeColumn.LoadFromStream(const Stream: TStream; Version: Integer);

  function ConvertOptions(Value: Cardinal): TVTColumnOptions;

  begin
    if Version >= 3 then
      Result := TVTColumnOptions(Word(Value and $FFFF))
    else
      if Version = 2 then
        Result := TVTColumnOptions(Word(Value and $FF))
      else
      begin
        
        Result := TVTColumnOptions(Word(Value) and $F);
        Value := (Value and not $F) shl 1;
        Result := Result + TVTColumnOptions(Word(Value and $FF));
      end;
  end;

var
  Dummy: Integer;
  S: UnicodeString;

begin
  with Stream do
  begin
    ReadBuffer(Dummy, SizeOf(Dummy));
    SetLength(S, Dummy);
    ReadBuffer(PWideChar(S)^, 2 * Dummy);
    Text := S;
    ReadBuffer(Dummy, SizeOf(Dummy));
    SetLength(FHint, Dummy);
    ReadBuffer(PWideChar(FHint)^, 2 * Dummy);
    ReadBuffer(Dummy, SizeOf(Dummy));
    Width := Dummy;
    ReadBuffer(Dummy, SizeOf(Dummy));
    MinWidth := Dummy;
    ReadBuffer(Dummy, SizeOf(Dummy));
    MaxWidth := Dummy;
    ReadBuffer(Dummy, SizeOf(Dummy));
    Style := TVirtualTreeColumnStyle(Dummy);
    ReadBuffer(Dummy, SizeOf(Dummy));
    ImageIndex := Dummy;
    ReadBuffer(Dummy, SizeOf(Dummy));
    Layout := TVTHeaderColumnLayout(Dummy);
    ReadBuffer(Dummy, SizeOf(Dummy));
    Margin := Dummy;
    ReadBuffer(Dummy, SizeOf(Dummy));
    Spacing := Dummy;
    ReadBuffer(Dummy, SizeOf(Dummy));
    BiDiMode := TBiDiMode(Dummy);

    ReadBuffer(Dummy, SizeOf(Dummy));
    Options := ConvertOptions(Dummy);

    if Version > 0 then
    begin
      
      ReadBuffer(Dummy, SizeOf(Dummy));
      Tag := Dummy;
      ReadBuffer(Dummy, SizeOf(Dummy));
      Alignment := TAlignment(Dummy);

      if Version > 1 then
      begin
        ReadBuffer(Dummy, SizeOf(Dummy));
        Color := TColor(Dummy);
      end;

      if Version > 5 then
      begin
        if coUseCaptionAlignment in FOptions then
        begin
          ReadBuffer(Dummy, SizeOf(Dummy));
          CaptionAlignment := TAlignment(Dummy);
        end;
      end;
    end;
  end;
end;

procedure TVirtualTreeColumn.ParentBiDiModeChanged;

var
  Columns: TVirtualTreeColumns;

begin
  if coParentBiDiMode in FOptions then
  begin
    Columns := GetOwner as TVirtualTreeColumns;
    if Assigned(Columns) and (FBidiMode <> Columns.FHeader.Treeview.BiDiMode) then
    begin
      FBiDiMode := Columns.FHeader.Treeview.BiDiMode;
      Changed(False);
    end;
  end;
end;

procedure TVirtualTreeColumn.ParentColorChanged;

var
  Columns: TVirtualTreeColumns;

begin
  if coParentColor in FOptions then
  begin
    Columns := GetOwner as TVirtualTreeColumns;
    if Assigned(Columns) and (FColor <> Columns.FHeader.Treeview.Color) then
    begin
      FColor := Columns.FHeader.Treeview.Color;
      Changed(False);
    end;
  end;
end;

procedure TVirtualTreeColumn.RestoreLastWidth;

begin
  TVirtualTreeColumns(GetOwner).AnimatedResize(Index, FLastWidth);
end;

procedure TVirtualTreeColumn.SaveToStream(const Stream: TStream);

var
  Dummy: Integer;

begin
  with Stream do
  begin
    Dummy := Length(FText);
    WriteBuffer(Dummy, SizeOf(Dummy));
    WriteBuffer(PWideChar(FText)^, 2 * Dummy);
    Dummy := Length(FHint);
    WriteBuffer(Dummy, SizeOf(Dummy));
    WriteBuffer(PWideChar(FHint)^, 2 * Dummy);
    WriteBuffer(FWidth, SizeOf(FWidth));
    WriteBuffer(FMinWidth, SizeOf(FMinWidth));
    WriteBuffer(FMaxWidth, SizeOf(FMaxWidth));
    Dummy := Ord(FStyle);
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := FImageIndex;
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := Ord(FLayout);
    WriteBuffer(Dummy, SizeOf(Dummy));
    WriteBuffer(FMargin, SizeOf(FMargin));
    WriteBuffer(FSpacing, SizeOf(FSpacing));
    Dummy := Ord(FBiDiMode);
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := Word(FOptions);
    WriteBuffer(Dummy, SizeOf(Dummy));
    
    WriteBuffer(FTag, SizeOf(Dummy));
    Dummy := Cardinal(FAlignment);
    WriteBuffer(Dummy, SizeOf(Dummy));
    
    Dummy := Integer(FColor);
    WriteBuffer(Dummy, SizeOf(Dummy));
    
    if coUseCaptionAlignment in FOptions then
    begin
      Dummy := Cardinal(FCaptionAlignment);
      WriteBuffer(Dummy, SizeOf(Dummy));
    end;
  end;
end;

function TVirtualTreeColumn.UseRightToLeftReading: Boolean;

begin
  Result := FBiDiMode <> bdLeftToRight;
end;

constructor TVirtualTreeColumns.Create(AOwner: TVTHeader);

var
  ColumnClass: TVirtualTreeColumnClass;

begin
  FHeader := AOwner;
  
  ColumnClass := AOwner.FOwner.GetColumnClass;
  
  inherited Create(ColumnClass);

  FHeaderBitmap := TBitmap.Create;
  FHeaderBitmap.PixelFormat := pf32Bit;

  FHoverIndex := NoColumn;
  FDownIndex := NoColumn;
  FClickIndex := NoColumn;
  FDropTarget := NoColumn;
  FTrackIndex := NoColumn;
  FDefaultWidth := 50;
end;

destructor TVirtualTreeColumns.Destroy;

begin
  FHeaderBitmap.Free;
  inherited;
end;

function TVirtualTreeColumns.GetCount: Integer;

begin
  Result := inherited Count;
end;

function TVirtualTreeColumns.GetItem(Index: TColumnIndex): TVirtualTreeColumn;

begin
  Result := TVirtualTreeColumn(inherited GetItem(Index));
end;

function TVirtualTreeColumns.GetNewIndex(P: TPoint; var OldIndex: TColumnIndex): Boolean;

var
  NewIndex: Integer;

begin
  Result := False;
  
  Inc(P.Y, FHeader.FHeight);
  NewIndex := ColumnFromPosition(P);
  if NewIndex <> OldIndex then
  begin
    if OldIndex > NoColumn then
      FHeader.Invalidate(Items[OldIndex]);
    OldIndex := NewIndex;
    if OldIndex > NoColumn then
      FHeader.Invalidate(Items[OldIndex]);
    Result := True;
  end;
end;

procedure TVirtualTreeColumns.SetDefaultWidth(Value: Integer);

begin
  FDefaultWidth := Value;
end;

procedure TVirtualTreeColumns.SetItem(Index: TColumnIndex; Value: TVirtualTreeColumn);

begin
  inherited SetItem(Index, Value);
end;

procedure TVirtualTreeColumns.AdjustAutoSize(CurrentIndex: TColumnIndex; Force: Boolean = False);

var
  NewValue,
  AutoIndex,
  Index,
  RestWidth: Integer;
  WasUpdating: Boolean;
begin
  if Count > 0 then
  begin
    
    AutoIndex := FHeader.FAutoSizeIndex;
    if (AutoIndex < 0) or (AutoIndex >= Count) then
      AutoIndex := Count - 1;

    if AutoIndex >= 0 then
    begin
      with FHeader.Treeview do
      begin
        if HandleAllocated then
          RestWidth := ClientWidth
        else
          RestWidth := Width;
      end;
      
      for Index := 0 to Count - 1 do
        if (Index <> AutoIndex) and (coVisible in Items[Index].FOptions) then
          Dec(RestWidth, Items[Index].Width);

      with Items[AutoIndex] do
      begin
        NewValue := Max(MinWidth, Min(MaxWidth, RestWidth));
        if Force or (FWidth <> NewValue) then
        begin
          FWidth := NewValue;
          UpdatePositions;
          WasUpdating := csUpdating in FHeader.Treeview.ComponentState;
          if not WasUpdating then
            FHeader.Treeview.Updating();
          try
            FHeader.Treeview.DoColumnResize(AutoIndex);
          finally
            if not WasUpdating then
              FHeader.Treeview.Updated();
          end;
        end;
      end;
    end;
  end;
end;

function TVirtualTreeColumns.AdjustDownColumn(P: TPoint): TColumnIndex;

begin
  
  Inc(P.Y, FHeader.FHeight);
  Result := ColumnFromPosition(P);
  if (Result > NoColumn) and (Result <> FDownIndex) and (coAllowClick in Items[Result].FOptions) and
    (coEnabled in Items[Result].FOptions) then
  begin
    if FDownIndex > NoColumn then
      FHeader.Invalidate(Items[FDownIndex]);
    FDownIndex := Result;
    FCheckBoxHit := Items[Result].FHasImage and PtInRect(Items[Result].FImageRect, P) and Items[Result].CheckBox;
    FHeader.Invalidate(Items[FDownIndex]);
  end;
end;

function TVirtualTreeColumns.AdjustHoverColumn(P: TPoint): Boolean;

begin
  Result := GetNewIndex(P, FHoverIndex);
end;

procedure TVirtualTreeColumns.AdjustPosition(Column: TVirtualTreeColumn; Position: Cardinal);

var
  OldPosition: Cardinal;

begin
  OldPosition := Column.Position;
  if OldPosition <> Position then
  begin
    if OldPosition < Position then
    begin
      
      Move(FPositionToIndex[OldPosition + 1], FPositionToIndex[OldPosition], (Position - OldPosition) * SizeOf(Cardinal));
    end
    else
    begin
      
      Move(FPositionToIndex[Position], FPositionToIndex[Position + 1], (OldPosition - Position) * SizeOf(Cardinal));
    end;
    FPositionToIndex[Position] := Column.Index;
  end;
end;

function TVirtualTreeColumns.CanSplitterResize(P: TPoint; Column: TColumnIndex): Boolean;

begin
  Result := (Column > NoColumn) and ([coResizable, coVisible] * Items[Column].FOptions = [coResizable, coVisible]);
  DoCanSplitterResize(P, Column, Result);
end;

procedure TVirtualTreeColumns.DoCanSplitterResize(P: TPoint; Column: TColumnIndex; var Allowed: Boolean);

begin
  if Assigned(FHeader.Treeview.FOnCanSplitterResizeColumn) then
    FHeader.Treeview.FOnCanSplitterResizeColumn(FHeader, P, Column, Allowed);
end;

procedure TVirtualTreeColumns.DrawButtonText(DC: HDC; Caption: UnicodeString; Bounds: TRect; Enabled, Hot: Boolean;
    DrawFormat: Cardinal; WrapCaption: Boolean);

var
  TextSpace: Integer;
  Size: TSize;

begin
  if not WrapCaption then
  begin
    
    GetTextExtentPoint32W(DC, PWideChar(Caption), Length(Caption), Size);
    TextSpace := Bounds.Right - Bounds.Left;
    if TextSpace < Size.cx then
      Caption := ShortenString(DC, Caption, TextSpace);
  end;

  SetBkMode(DC, TRANSPARENT);
  if not Enabled then
    if FHeader.Treeview.VclStyleEnabled then
    begin
      SetTextColor(DC, ColorToRGB(FHeader.Treeview.FColors.HeaderFontColor));
      Windows.DrawTextW(DC, PWideChar(Caption), Length(Caption), Bounds, DrawFormat);
    end
    else
  begin
    OffsetRect(Bounds, 1, 1);
    SetTextColor(DC, ColorToRGB(clBtnHighlight));
    Windows.DrawTextW(DC, PWideChar(Caption), Length(Caption), Bounds, DrawFormat);
    OffsetRect(Bounds, -1, -1);
    SetTextColor(DC, ColorToRGB(clBtnShadow));
    Windows.DrawTextW(DC, PWideChar(Caption), Length(Caption), Bounds, DrawFormat);
  end
  else
  begin
    if Hot then
      SetTextColor(DC, ColorToRGB(FHeader.Treeview.FColors.HeaderHotColor))
    else
      SetTextColor(DC, ColorToRGB(FHeader.Treeview.FColors.HeaderFontColor));
    Windows.DrawTextW(DC, PWideChar(Caption), Length(Caption), Bounds, DrawFormat);
  end;
end;

procedure TVirtualTreeColumns.FixPositions;

var
  I: Integer;

begin
  for I := 0 to Count - 1 do
    FPositionToIndex[Items[I].Position] := I;

  FNeedPositionsFix := False;
  UpdatePositions(True);
end;

function TVirtualTreeColumns.GetColumnAndBounds(P: TPoint; var ColumnLeft, ColumnRight: Integer;
  Relative: Boolean = True): Integer;

var
  I: Integer;

begin
  Result := InvalidColumn;
  if Relative and (P.X >= Header.Columns.GetVisibleFixedWidth) then
    ColumnLeft := -FHeader.Treeview.FEffectiveOffsetX
  else
    ColumnLeft := 0;

  if FHeader.Treeview.UseRightToLeftAlignment then
    Inc(ColumnLeft, FHeader.Treeview.ComputeRTLOffset(True));

  for I := 0 to Count - 1 do
    with Items[FPositionToIndex[I]] do
      if coVisible in FOptions then
      begin
        ColumnRight := ColumnLeft + FWidth;
        if P.X < ColumnRight then
        begin
          Result := FPositionToIndex[I];
          Exit;
        end;
        ColumnLeft := ColumnRight;
      end;
end;

function TVirtualTreeColumns.GetOwner: TPersistent;

begin
  Result := FHeader;
end;

procedure TVirtualTreeColumns.HandleClick(P: TPoint; Button: TMouseButton; Force, DblClick: Boolean);

var
  HitInfo: TVTHeaderHitInfo;
  NewClickIndex: Integer;

begin
  
  Inc(P.Y, FHeader.FHeight);
  NewClickIndex := ColumnFromPosition(P);
  with HitInfo do
  begin
    X := P.X;
    Y := P.Y;
    Shift := FHeader.GetShiftState;
    if DblClick then
      Shift := Shift + [ssDouble];
  end;
  HitInfo.Button := Button;

  if (NewClickIndex > NoColumn) and (coAllowClick in Items[NewClickIndex].FOptions) and
    ((NewClickIndex = FDownIndex) or Force) then
  begin
    FClickIndex := NewClickIndex;
    HitInfo.Column := NewClickIndex;
    HitInfo.HitPosition := [hhiOnColumn];

    if Items[NewClickIndex].FHasImage and PtInRect(Items[NewClickIndex].FImageRect, P) then
    begin
      Include(HitInfo.HitPosition, hhiOnIcon);
      if Items[NewClickIndex].CheckBox then
      begin
        if Button = mbLeft then
          FHeader.Treeview.UpdateColumnCheckState(Items[NewClickIndex]);
        Include(HitInfo.HitPosition, hhiOnCheckbox);
      end;
    end;
  end
  else
  begin
    FClickIndex := NoColumn;
    HitInfo.Column := NoColumn;
    HitInfo.HitPosition := [hhiNoWhere];
  end;

  if (hoHeaderClickAutoSort in Header.Options) and (HitInfo.Button = mbLeft) and not DblClick and not (hhiOnCheckbox in HitInfo.HitPosition) and (HitInfo.Column >= 0) then begin
    
    if HitInfo.Column<>Header.SortColumn then begin
      
      Header.SortColumn := HitInfo.Column;
      Header.SortDirection := Self[Header.SortColumn].DefaultSortDirection
    end
    else begin
      
      if Header.SortDirection = sdDescending then
        Header.SortDirection := sdAscending
      else
        Header.SortDirection := sdDescending
    end;
  end;

  if DblClick then
    FHeader.Treeview.DoHeaderDblClick(HitInfo)
  else
    FHeader.Treeview.DoHeaderClick(HitInfo);

  if not (hhiNoWhere in HitInfo.HitPosition) then
    FHeader.Invalidate(Items[NewClickIndex]);
  if (FClickIndex > NoColumn) and (FClickIndex <> NewClickIndex) then
    FHeader.Invalidate(Items[FClickIndex]);
end;

procedure TVirtualTreeColumns.IndexChanged(OldIndex, NewIndex: Integer);

var
  I: Integer;
  Increment: Integer;
  Lower,
  Upper: Integer;

begin
  if NewIndex = -1 then
  begin
    
    Upper := High(FPositionToIndex);
    for I := 0 to Upper do
    begin
      if FPositionToIndex[I] = OldIndex then
      begin
        
        if I < Upper then
          Move(FPositionToIndex[I + 1], FPositionToIndex[I], (Upper - I) * SizeOf(TColumnIndex));
      end;
      
      if FPositionToIndex[I] > OldIndex then
        Dec(FPositionToIndex[I]);
    end;
    SetLength(FPositionToIndex, High(FPositionToIndex));
  end
  else
  begin
    if OldIndex < NewIndex then
      Increment := -1
    else
      Increment := 1;

    Lower := Min(OldIndex, NewIndex);
    Upper := Max(OldIndex, NewIndex);
    for I := 0 to High(FPositionToIndex) do
    begin
      if (FPositionToIndex[I] >= Lower) and (FPositionToIndex[I] < Upper) then
        Inc(FPositionToIndex[I], Increment)
      else
        if FPositionToIndex[I] = OldIndex then
          FPositionToIndex[I] := NewIndex;
    end;
  end;
end;

procedure TVirtualTreeColumns.InitializePositionArray;

var
  I, OldSize: Integer;
  Changed: Boolean;

begin
  if Count <> Length(FPositionToIndex) then
  begin
    OldSize := Length(FPositionToIndex);
    SetLength(FPositionToIndex, Count);
    if Count > OldSize then
    begin
      
      for I := OldSize to Count - 1 do
        FPositionToIndex[I] := I;
    end
    else
    begin
      
      repeat
        Changed := False;
        for I := 0 to Count - 1 do
          if FPositionToIndex[I] >= Count then
          begin
            Dec(FPositionToIndex[I]);
            Changed := True;
          end;
      until not Changed;
    end;
  end;
end;

procedure TVirtualTreeColumns.Notify(Item: TCollectionItem; Action: TCollectionNotification);

begin
//TCollectionNotification = (cnAdding, cnAdded, cnExtracting, cnExtracted, cnDeleting, cnRemoved);
  if Action in [cnExtracting, cnDeleting] then
    with Header.Treeview do
      if not (csLoading in ComponentState) and (FFocusedColumn = Item.Index) then
        FFocusedColumn := NoColumn;
end;

procedure TVirtualTreeColumns.ReorderColumns(RTL: Boolean);

var
  I: Integer;

begin
  if RTL then
  begin
    for I := 0 to Count - 1 do
      FPositionToIndex[I] := Count - I - 1;
  end
  else
  begin
    for I := 0 to Count - 1 do
      FPositionToIndex[I] := I;
  end;

  UpdatePositions(True);
end;

procedure TVirtualTreeColumns.Update(Item: TCollectionItem);

begin
  
  InitializePositionArray;
  if csLoading in Header.Treeview.ComponentState then
    FNeedPositionsFix := True
  else
    UpdatePositions;
  
  if (Count > 0) and (Header.FMainColumn < 0) then
    FHeader.FMainColumn := 0;

  if not (csLoading in Header.Treeview.ComponentState) and not (hsLoading in FHeader.FStates) then
  begin
    with FHeader do
    begin
      if hoAutoResize in FOptions then
        AdjustAutoSize(InvalidColumn);
      if Assigned(Item) then
        Invalidate(Item as TVirtualTreeColumn)
      else
        if Treeview.HandleAllocated then
        begin
          Treeview.UpdateHorizontalScrollBar(False);
          Invalidate(nil);
          Treeview.Invalidate;
        end;

      if not (tsUpdating in Treeview.FStates) then
        
        Treeview.UpdateDesigner;
    end;
  end;
end;

procedure TVirtualTreeColumns.UpdatePositions(Force: Boolean = False);

var
  I, RunningPos: Integer;

begin
  if not FNeedPositionsFix and (Force or (UpdateCount = 0)) then
  begin
    RunningPos := 0;
    for I := 0 to High(FPositionToIndex) do
      with Items[FPositionToIndex[I]] do
      begin
        FPosition := I;
        FLeft := RunningPos;
        if coVisible in FOptions then
          Inc(RunningPos, FWidth);
      end;
  end;
end;

function TVirtualTreeColumns.Add: TVirtualTreeColumn;

begin
  Result := TVirtualTreeColumn(inherited Add);
end;

procedure TVirtualTreeColumns.AnimatedResize(Column: TColumnIndex; NewWidth: Integer);

var
  OldWidth: Integer;
  DC: HDC;
  I,
  Steps,
  DX: Integer;
  HeaderScrollRect,
  ScrollRect,
  R: TRect;

  NewBrush,
  LastBrush: HBRUSH;

begin
  if not IsValidColumn(Column) then exit; 
  
  if NewWidth < Items[Column].FMinWidth then
     NewWidth := Items[Column].FMinWidth;
  if NewWidth > Items[Column].FMaxWidth then
     NewWidth := Items[Column].FMaxWidth;

  OldWidth := Items[Column].Width;
  
  if OldWidth <> NewWidth then
  begin
    if not ( (hoDisableAnimatedResize in FHeader.Options) or
             (coDisableAnimatedResize in Items[Column].Options) ) then
    begin
      DC := GetWindowDC(FHeader.Treeview.Handle);
      with FHeader.Treeview do
      try
        Steps := 32;
        DX := (NewWidth - OldWidth) div Steps;
        
        HeaderScrollRect := FHeaderRect;
        ScrollRect := HeaderScrollRect;
        
        ScrollRect.Top := ScrollRect.Bottom;
        ScrollRect.Bottom := ScrollRect.Top + ClientHeight;
        ScrollRect.Right := ScrollRect.Left + ClientWidth;
        with Items[Column] do
          Inc(ScrollRect.Left, FLeft + FWidth);
        HeaderScrollRect.Left := ScrollRect.Left;
        HeaderScrollRect.Right := ScrollRect.Right;
        
        if NewWidth > OldWidth then
        begin
          R := ScrollRect;
          NewBrush := CreateSolidBrush(ColorToRGB(Color));
          LastBrush := SelectObject(DC, NewBrush);
          R.Right := R.Left + DX;
          FillRect(DC, R, NewBrush);
          SelectObject(DC, LastBrush);
          DeleteObject(NewBrush);
        end
        else
        begin
          Inc(HeaderScrollRect.Left, DX);
          Inc(ScrollRect.Left, DX);
        end;

        for I := 0 to Steps - 1 do
        begin
          ScrollDC(DC, DX, 0, HeaderScrollRect, HeaderScrollRect, 0, nil);
          Inc(HeaderScrollRect.Left, DX);
          ScrollDC(DC, DX, 0, ScrollRect, ScrollRect, 0, nil);
          Inc(ScrollRect.Left, DX);
          Sleep(1);
        end;
      finally
        ReleaseDC(Handle, DC);
      end;
    end;
    Items[Column].Width := NewWidth;
  end;
end;

procedure TVirtualTreeColumns.Assign(Source: TPersistent);

begin
  
  inherited;

  if Source is TVirtualTreeColumns then
  begin
    
    FPositionToIndex := Copy(TVirtualTreeColumns(Source).FPositionToIndex, 0, MaxInt);
    
    FNeedPositionsFix := False;
    UpdatePositions(True);
  end;
end;

procedure TVirtualTreeColumns.Clear;

begin
  FClearing := True;
  try
    Header.Treeview.CancelEditNode;
    
    FHoverIndex := NoColumn;
    FDownIndex := NoColumn;
    FTrackIndex := NoColumn;
    FClickIndex := NoColumn;
    FCheckBoxHit := False;

    with Header do
      if not (hsLoading in FStates) then
      begin
        FAutoSizeIndex := NoColumn;
        FMainColumn := NoColumn;
        FSortColumn := NoColumn;
      end;

    with Header.Treeview do
      if not (csLoading in ComponentState) then
        FFocusedColumn := NoColumn;

    inherited Clear;
  finally
    FClearing := False;
  end;
end;

function TVirtualTreeColumns.ColumnFromPosition(P: TPoint; Relative: Boolean = True): TColumnIndex;

var
  I, Sum: Integer;

begin
  Result := InvalidColumn;
  
  if (P.X >= 0) and (P.Y >= 0) and (P.Y <= FHeader.TreeView.Height) then
    with FHeader, Treeview do
    begin
      if Relative and (P.X > GetVisibleFixedWidth) then
        Sum := -FEffectiveOffsetX
      else
        Sum := 0;

      if UseRightToLeftAlignment then
        Inc(Sum, ComputeRTLOffset(True));

      for I := 0 to Count - 1 do
        if coVisible in Items[FPositionToIndex[I]].FOptions then
        begin
          Inc(Sum, Items[FPositionToIndex[I]].Width);
          if P.X < Sum then
          begin
            Result := FPositionToIndex[I];
            Break;
          end;
        end;
    end;
end;

function TVirtualTreeColumns.ColumnFromPosition(PositionIndex: TColumnPosition): TColumnIndex;

begin
  if Integer(PositionIndex) < Length(FPositionToIndex) then
    Result := FPositionToIndex[PositionIndex]
  else
    Result := NoColumn;
end;

function TVirtualTreeColumns.Equals(OtherColumnsObj: TObject): Boolean;

var
  I: Integer;
  OtherColumns : TVirtualTreeColumns;

begin
  if not (OtherColumnsObj is TVirtualTreeColumns) then
  begin
    Result := False;
    Exit
  end;

  OtherColumns := TVirtualTreeColumns (OtherColumnsObj);
  
  Result := OtherColumns.Count = Count;
  if Result then
  begin
    
    Result := CompareMem(Pointer(FPositionToIndex), Pointer(OtherColumns.FPositionToIndex),
      Length(FPositionToIndex) * SizeOf(TColumnIndex));
    if Result then
    begin
      for I := 0 to Count - 1 do
        if not Items[I].Equals(OtherColumns[I]) then
        begin
          Result := False;
          Break;
        end;
    end;
  end;
end;

procedure TVirtualTreeColumns.GetColumnBounds(Column: TColumnIndex; var Left, Right: Integer);

begin
  if Column <= NoColumn then
  begin
    Left := 0;
    Right := FHeader.Treeview.ClientWidth;
  end
  else
  begin
    Left := Items[Column].Left;
    Right := Left + Items[Column].Width;
    if FHeader.Treeview.UseRightToLeftAlignment then
    begin
      Inc(Left, FHeader.Treeview.ComputeRTLOffset(True));
      Inc(Right, FHeader.Treeview.ComputeRTLOffset(True));
    end;
  end;
end;

function TVirtualTreeColumns.GetScrollWidth: Integer;

var
  I: Integer;
  ScrollColumnCount: Integer;

begin

  Result := 0;

  ScrollColumnCount := 0;
  for I := 0 to FHeader.Columns.Count - 1 do
  begin
    if ([coVisible, coFixed] * FHeader.Columns[I].Options = [coVisible]) then
    begin
      Inc(Result, FHeader.Columns[I].Width);
      Inc(ScrollColumnCount);
    end;
  end;

  if ScrollColumnCount > 0 then 
    Result := Round(Result / ScrollColumnCount)
  else 
    Result := Integer(FHeader.Treeview.FIndent);

end;

function TVirtualTreeColumns.GetFirstVisibleColumn(ConsiderAllowFocus: Boolean = False): TColumnIndex;

var
  I: Integer;

begin
  Result := InvalidColumn;
  for I := 0 to Count - 1 do
    if (coVisible in Items[FPositionToIndex[I]].FOptions) and
       ( (not ConsiderAllowFocus) or
         (coAllowFocus in Items[FPositionToIndex[I]].FOptions)
       ) then
    begin
      Result := FPositionToIndex[I];
      Break;
    end;
end;

function TVirtualTreeColumns.GetLastVisibleColumn(ConsiderAllowFocus: Boolean = False): TColumnIndex;

var
  I: Integer;

begin
  Result := InvalidColumn;
  for I := Count - 1 downto 0 do
    if (coVisible in Items[FPositionToIndex[I]].FOptions) and
       ( (not ConsiderAllowFocus) or
         (coAllowFocus in Items[FPositionToIndex[I]].FOptions)
       ) then
    begin
      Result := FPositionToIndex[I];
      Break;
    end;
end;

function TVirtualTreeColumns.GetFirstColumn: TColumnIndex;

begin
  if Count = 0 then
    Result := InvalidColumn
  else
    Result := FPositionToIndex[0];
end;

function TVirtualTreeColumns.GetNextColumn(Column: TColumnIndex): TColumnIndex;

var
  Position: Integer;

begin
  if Column < 0 then
    Result := InvalidColumn
  else
  begin
    Position := Items[Column].Position;
    if Position < Count - 1 then
      Result := FPositionToIndex[Position + 1]
    else
      Result := InvalidColumn;
  end;
end;

function TVirtualTreeColumns.GetNextVisibleColumn(Column: TColumnIndex; ConsiderAllowFocus: Boolean = False): TColumnIndex;

begin
  Result := Column;
  repeat
    Result := GetNextColumn(Result);
  until (Result = InvalidColumn) or
        ( (coVisible in Items[Result].FOptions) and
          ( (not ConsiderAllowFocus) or
            (coAllowFocus in Items[Result].FOptions)
          )
        );
end;

function TVirtualTreeColumns.GetPreviousColumn(Column: TColumnIndex): TColumnIndex;

var
  Position: Integer;

begin
  if Column < 0 then
    Result := InvalidColumn
  else
  begin
    Position := Items[Column].Position;
    if Position > 0 then
      Result := FPositionToIndex[Position - 1]
    else
      Result := InvalidColumn;
  end;
end;

function TVirtualTreeColumns.GetPreviousVisibleColumn(Column: TColumnIndex; ConsiderAllowFocus: Boolean = False): TColumnIndex;

begin
  Result := Column;
  repeat
    Result := GetPreviousColumn(Result);
  until (Result = InvalidColumn) or
        ( (coVisible in Items[Result].FOptions) and
          ( (not ConsiderAllowFocus) or
            (coAllowFocus in Items[Result].FOptions)
          )
        );
end;

function TVirtualTreeColumns.GetVisibleColumns: TColumnsArray;

var
  I, Counter: Integer;

begin
  SetLength(Result, Count);
  Counter := 0;

  for I := 0 to Count - 1 do
    if coVisible in Items[FPositionToIndex[I]].FOptions then
    begin
      Result[Counter] := Items[FPositionToIndex[I]];
      Inc(Counter);
    end;
  
  SetLength(Result, Counter);
end;

function TVirtualTreeColumns.GetVisibleFixedWidth: Integer;

var
  I: Integer;

begin
  Result := 0;
  for I := 0 to Count - 1 do
  begin
    if Items[I].Options * [coVisible, coFixed] = [coVisible, coFixed] then
      Inc(Result, Items[I].Width);
  end;
end;

function TVirtualTreeColumns.IsValidColumn(Column: TColumnIndex): Boolean;

begin
  Result := (Column > NoColumn) and (Column < Count);
end;

procedure TVirtualTreeColumns.LoadFromStream(const Stream: TStream; Version: Integer);

var
  I,
  ItemCount: Integer;

begin
  Clear;
  Stream.ReadBuffer(ItemCount, SizeOf(ItemCount));
  
  if ItemCount > 0 then
  begin
    BeginUpdate;
    try
      for I := 0 to ItemCount - 1 do
        Add.LoadFromStream(Stream, Version);
      SetLength(FPositionToIndex, ItemCount);
      Stream.ReadBuffer(FPositionToIndex[0], ItemCount * SizeOf(TColumnIndex));
      UpdatePositions(True);
    finally
      EndUpdate;
    end;
  end;
  
  if Version > 4 then
    Stream.ReadBuffer(FDefaultWidth, SizeOf(FDefaultWidth));
end;

procedure TVirtualTreeColumns.PaintHeader(DC: HDC; R: TRect; HOffset: Integer);

var
  VisibleFixedWidth: Integer;
  RTLOffset: Integer;

  procedure PaintFixedArea;
  
  begin
    if VisibleFixedWidth > 0 then
      PaintHeader(FHeaderBitmap.Canvas,
        Rect(0, 0, Min(R.Right, VisibleFixedWidth), R.Bottom - R.Top),
        Point(R.Left, R.Top), RTLOffset);
  end;

begin
  
  with TWithSafeRect(FHeader.Treeview.FHeaderRect) do
  begin
    FHeaderBitmap.Width := Max(Right, R.Right - R.Left);
    FHeaderBitmap.Height := Bottom;
  end;

  VisibleFixedWidth := GetVisibleFixedWidth;
  
  if FHeader.TreeView.UseRightToLeftAlignment then
    RTLOffset := FHeader.Treeview.ComputeRTLOffset
  else
    RTLOffset := 0;
    
  if RTLOffset = 0 then
    PaintFixedArea;
  
  PaintHeader(FHeaderBitmap.Canvas,
    Rect(VisibleFixedWidth - HOffset, 0, R.Right + VisibleFixedWidth - HOffset, R.Bottom - R.Top),
    Point(R.Left + VisibleFixedWidth, R.Top), RTLOffset);
  
  if RTLOffset <> 0 then
    PaintFixedArea;
  
  with TWithSafeRect(R) do
    BitBlt(DC, Left, Top, Right - Left, Bottom - Top, FHeaderBitmap.Canvas.Handle, Left, Top, SRCCOPY);
end;

procedure TVirtualTreeColumns.PaintHeader(TargetCanvas: TCanvas; R: TRect; const Target: TPoint;
  RTLOffset: Integer = 0);

const
  SortGlyphs: array[TSortDirection, Boolean] of Integer = ( 
    (3, 5) , (2, 4) 
  );

var
  Run: TColumnIndex;
  RightBorderFlag,
  NormalButtonStyle,
  NormalButtonFlags,
  PressedButtonStyle,
  PressedButtonFlags,
  RaisedButtonStyle,
  RaisedButtonFlags: Cardinal;
  Images: TCustomImageList;
  OwnerDraw,
  AdvancedOwnerDraw: Boolean;
  PaintInfo: THeaderPaintInfo;
  RequestedElements,
  ActualElements: THeaderPaintElements;

  procedure PrepareButtonStyles;

  begin
    RaisedButtonStyle := 0;
    RaisedButtonFlags := 0;
    case FHeader.Style of
      hsThickButtons:
        begin
          NormalButtonStyle := BDR_RAISEDINNER or BDR_RAISEDOUTER;
          NormalButtonFlags := BF_LEFT or BF_TOP or BF_BOTTOM or BF_MIDDLE or BF_SOFT or BF_ADJUST;
          PressedButtonStyle := BDR_RAISEDINNER or BDR_RAISEDOUTER;
          PressedButtonFlags := NormalButtonFlags or BF_RIGHT or BF_FLAT or BF_ADJUST;
        end;
      hsFlatButtons:
        begin
          NormalButtonStyle := BDR_RAISEDINNER;
          NormalButtonFlags := BF_LEFT or BF_TOP or BF_BOTTOM or BF_MIDDLE or BF_ADJUST;
          PressedButtonStyle := BDR_SUNKENOUTER;
          PressedButtonFlags := BF_RECT or BF_MIDDLE or BF_ADJUST;
        end;
    else
      
      begin
        NormalButtonStyle := BDR_RAISEDINNER;
        NormalButtonFlags := BF_RECT or BF_MIDDLE or BF_SOFT or BF_ADJUST;
        PressedButtonStyle := BDR_SUNKENOUTER;
        PressedButtonFlags := BF_RECT or BF_MIDDLE or BF_ADJUST;
        RaisedButtonStyle := BDR_RAISEDINNER;
        RaisedButtonFlags := BF_LEFT or BF_TOP or BF_BOTTOM or BF_MIDDLE or BF_ADJUST;
      end;
    end;
  end;

  procedure DrawBackground;

  var
    BackgroundRect: TRect;
    Details: TThemedElementDetails;

  begin
    BackgroundRect := Rect(Target.X, Target.Y, Target.X + R.Right - R.Left, Target.Y + FHeader.Height);

    with TargetCanvas do
      begin
      if hpeBackground in RequestedElements then begin
        PaintInfo.PaintRectangle := BackgroundRect;
        FHeader.Treeview.DoAdvancedHeaderDraw(PaintInfo, [hpeBackground]);
      end  
      else
      begin
        if tsUseThemes in FHeader.Treeview.FStates then
        begin
          Details := StyleServices.GetElementDetails(thHeaderItemRightNormal);
          StyleServices.DrawElement(Handle, Details, BackgroundRect, @BackgroundRect);
        end
        else begin
          Brush.Color :=  FHeader.FBackground;
          FillRect(BackgroundRect);
        end;
      end;
    end;
  end;

  procedure PaintColumnHeader(AColumn: TColumnIndex; ATargetRect: TRect);

  var
    Y: Integer;
    SavedDC: Integer;
    ColCaptionText: UnicodeString;
    ColImageInfo: TVTImageInfo;
    SortIndex: Integer;
    SortGlyphSize: TSize;
    Glyph: TThemedHeader;
    Details: TThemedElementDetails;
    WrapCaption: Boolean;
    DrawFormat: Cardinal;
    Pos: TRect;
    DrawHot: Boolean;
    ImageWidth: Integer;
  begin
    ColImageInfo.Ghosted := False;
    PaintInfo.Column := Items[AColumn];
    with PaintInfo, Column do
    begin
      IsHoverIndex := (AColumn = FHoverIndex) and (hoHotTrack in FHeader.FOptions) and (coEnabled in FOptions);
      IsDownIndex := (AColumn = FDownIndex) and not FCheckBoxHit;

      if (coShowDropMark in FOptions) and (AColumn = FDropTarget) and (AColumn <> FDragIndex) then
      begin
        if FDropBefore then
          DropMark := dmmLeft
        else
          DropMark := dmmRight;
      end
      else
        DropMark := dmmNone;

      IsEnabled := (coEnabled in FOptions) and (FHeader.Treeview.Enabled);
      ShowHeaderGlyph := (hoShowImages in FHeader.FOptions) and ((Assigned(Images) and (FImageIndex > -1)) or FCheckBox);
      ShowSortGlyph := (AColumn = FHeader.FSortColumn) and (hoShowSortGlyphs in FHeader.FOptions);
      WrapCaption := coWrapCaption in FOptions;

      PaintRectangle := ATargetRect;
      
      if (Style = vsText) or not OwnerDraw or AdvancedOwnerDraw then
      begin
        
        RequestedElements := [];
        if AdvancedOwnerDraw then
        begin
          PaintInfo.Column := Items[AColumn];
          FHeader.Treeview.DoHeaderDrawQueryElements(PaintInfo, RequestedElements);
        end;

        if ShowRightBorder or (AColumn < Count - 1) then
          RightBorderFlag := BF_RIGHT
        else
          RightBorderFlag := 0;

        if hpeBackground in RequestedElements then
          FHeader.Treeview.DoAdvancedHeaderDraw(PaintInfo, [hpeBackground])
        else
        begin
          if tsUseThemes in FHeader.Treeview.FStates then
          begin
            if IsDownIndex then
              Details := StyleServices.GetElementDetails(thHeaderItemPressed)
            else
              if IsHoverIndex then
                Details := StyleServices.GetElementDetails(thHeaderItemHot)
              else
                Details := StyleServices.GetElementDetails(thHeaderItemNormal);
            StyleServices.DrawElement(TargetCanvas.Handle, Details, PaintRectangle, @PaintRectangle);
          end
          else
          begin
            if IsDownIndex then
              DrawEdge(TargetCanvas.Handle, PaintRectangle, PressedButtonStyle, PressedButtonFlags)
            else
              
              if (FHeader.Style = hsPlates) and IsHoverIndex and
                (coAllowClick in FOptions) and (coEnabled in FOptions) then
                DrawEdge(TargetCanvas.Handle, PaintRectangle, RaisedButtonStyle,
                         RaisedButtonFlags or RightBorderFlag)
              else
                DrawEdge(TargetCanvas.Handle, PaintRectangle, NormalButtonStyle,
                         NormalButtonFlags or RightBorderFlag);
          end;
        end;

        PaintRectangle := ATargetRect;
        
        InflateRect(PaintRectangle, -2, -2);
        DrawFormat := DT_TOP or DT_NOPREFIX;
        case CaptionAlignment of
          taLeftJustify  : DrawFormat := DrawFormat or DT_LEFT;
          taRightJustify : DrawFormat := DrawFormat or DT_RIGHT;
          taCenter       : DrawFormat := DrawFormat or DT_CENTER;
        end;
        if UseRightToLeftReading then
          DrawFormat := DrawFormat + DT_RTLREADING;
        ComputeHeaderLayout(TargetCanvas.Handle, PaintRectangle, ShowHeaderGlyph, ShowSortGlyph, GlyphPos,
          SortGlyphPos, SortGlyphSize, TextRectangle, DrawFormat);
        
        if IsDownIndex then
        begin
          OffsetRect(TextRectangle, 1, 1);
          Inc(GlyphPos.X);
          Inc(GlyphPos.Y);
          Inc(SortGlyphPos.X);
          Inc(SortGlyphPos.Y);
        end;
        
        ActualElements := RequestedElements * [hpeHeaderGlyph, hpeSortGlyph, hpeDropMark, hpeText];
        
        FHasImage := False;
        if Assigned(Images) then
          ImageWidth := Images.Width
        else
          ImageWidth := 0;

        if not (hpeHeaderGlyph in ActualElements) and ShowHeaderGlyph and
          (not ShowSortGlyph or (FBidiMode <> bdLeftToRight) or (GlyphPos.X + ImageWidth <= SortGlyphPos.X) ) then
        begin
          if not FCheckBox then
          begin
            ColImageInfo.Images := Images;
            Images.Draw(TargetCanvas, GlyphPos.X, GlyphPos.Y, FImageIndex, IsEnabled);
          end
          else
          begin
            with Header.Treeview do
            begin
              ColImageInfo.Images := GetCheckImageListFor(CheckImageKind);
              ColImageInfo.Index := GetCheckImage(nil, FCheckType, FCheckState, IsEnabled);
              ColImageInfo.XPos := GlyphPos.X;
              ColImageInfo.YPos := GlyphPos.Y;
              PaintCheckImage(TargetCanvas, ColImageInfo, False);
            end;
          end;

          FHasImage := True;
          with TWithSafeRect(FImageRect) do
          begin
            Left := GlyphPos.X;
            Top := GlyphPos.Y;
            Right := Left + ColImageInfo.Images.Width;
            Bottom := Top + ColImageInfo.Images.Height;
          end;
        end;
        
        if WrapCaption then
          ColCaptionText := FCaptionText
        else
          ColCaptionText := Text;
          if IsHoverIndex and FHeader.Treeview.VclStyleEnabled then
            DrawHot := True
          else
            DrawHot := (IsHoverIndex and (hoHotTrack in FHeader.FOptions) and not(tsUseThemes in FHeader.Treeview.FStates));
          if not(hpeText in ActualElements) and (Length(Text) > 0) then
            DrawButtonText(TargetCanvas.Handle, ColCaptionText, TextRectangle, IsEnabled, DrawHot, DrawFormat, WrapCaption);
        
        if not (hpeSortGlyph in ActualElements) and ShowSortGlyph then
        begin
          if tsUseExplorerTheme in FHeader.Treeview.FStates then
          begin
            Pos.TopLeft := SortGlyphPos;
            Pos.Right := Pos.Left + SortGlyphSize.cx;
            Pos.Bottom := Pos.Top + SortGlyphSize.cy;
            if FHeader.FSortDirection = sdAscending then
              Glyph := thHeaderSortArrowSortedUp
            else
              Glyph := thHeaderSortArrowSortedDown;
            Details := StyleServices.GetElementDetails(Glyph);
            StyleServices.DrawElement(TargetCanvas.Handle, Details, Pos, @Pos);
          end
          else
          begin
            SortIndex := SortGlyphs[FHeader.FSortDirection, tsUseThemes in FHeader.Treeview.FStates];
            UtilityImages.Draw(TargetCanvas, SortGlyphPos.X, SortGlyphPos.Y, SortIndex);
          end;
        end;
        
        if not (hpeDropMark in ActualElements) and (DropMark <> dmmNone) then
        begin
          Y := (PaintRectangle.Top + PaintRectangle.Bottom - UtilityImages.Height) div 2;
          if DropMark = dmmLeft then
            UtilityImages.Draw(TargetCanvas, PaintRectangle.Left, Y, 0)
          else
            UtilityImages.Draw(TargetCanvas, PaintRectangle.Right - 16 , Y,  1);
        end;

        if ActualElements <> [] then
        begin
          SavedDC := SaveDC(TargetCanvas.Handle);
          FHeader.Treeview.DoAdvancedHeaderDraw(PaintInfo, ActualElements);
          RestoreDC(TargetCanvas.Handle, SavedDC);
        end;
      end
      else 
        FHeader.Treeview.DoHeaderDraw(TargetCanvas, Items[AColumn], PaintRectangle, IsHoverIndex, IsDownIndex,
          DropMark);
    end;
  end;

var
  TargetRect: TRect;
  MaxX: Integer;

begin
  if IsRectEmpty(R) then
    Exit;
  
  AdvancedOwnerDraw := (hoOwnerDraw in FHeader.FOptions) and Assigned(FHeader.Treeview.FOnAdvancedHeaderDraw) and
    Assigned(FHeader.Treeview.FOnHeaderDrawQueryElements) and not (csDesigning in FHeader.Treeview.ComponentState);
  OwnerDraw := (hoOwnerDraw in FHeader.FOptions) and Assigned(FHeader.Treeview.FOnHeaderDraw) and
    not (csDesigning in FHeader.Treeview.ComponentState) and not AdvancedOwnerDraw;

  ZeroMemory(@PaintInfo, SizeOf(PaintInfo));
  PaintInfo.TargetCanvas := TargetCanvas;

  with PaintInfo, TargetCanvas do
  begin
    
    Images := FHeader.FImages;
    Font := FHeader.FFont;

    PrepareButtonStyles;
    
    RequestedElements := [];
    if AdvancedOwnerDraw then
    begin
      PaintRectangle := R;
      Column := nil;
      FHeader.Treeview.DoHeaderDrawQueryElements(PaintInfo, RequestedElements);
    end;
    
    DrawBackground;
    
    R := Rect(Max(R.Left, 0), Max(R.Top, 0), Min(R.Right, TotalWidth), Min(R.Bottom, Header.Height));
    
    MaxX := Target.X + R.Right - R.Left;
    
    Run := ColumnFromPosition(Point(R.Left + RTLOffset, 0), False);
    if Run <= NoColumn then
      Exit;

    TargetRect.Top    := Target.Y;
    TargetRect.Bottom := Target.Y + R.Bottom - R.Top;
    TargetRect.Left   := Target.X - R.Left + Items[Run].FLeft + RTLOffset;

    ShowRightBorder := (FHeader.Style = hsThickButtons) or not (hoAutoResize in FHeader.FOptions) or
      (FHeader.Treeview.BevelKind = bkNone);
    
    while (Run > NoColumn) and (TargetRect.Left < MaxX) do
    begin
      TargetRect.Right := TargetRect.Left + Items[Run].FWidth;
      
      ClipCanvas(TargetCanvas, Rect(Max(TargetRect.Left, Target.X), Target.Y + R.Top,
                                    Min(TargetRect.Right, MaxX), TargetRect.Bottom));

      PaintColumnHeader(Run, TargetRect);

      SelectClipRgn(Handle, 0);
      
      TargetRect.Left := TargetRect.Right;
      Run := GetNextVisibleColumn(Run)
    end;
  end;
end;

procedure TVirtualTreeColumns.SaveToStream(const Stream: TStream);

var
  I: Integer;

begin
  I := Count;
  Stream.WriteBuffer(I, SizeOf(I));
  if I > 0 then
  begin
    for I := 0 to Count - 1 do
      TVirtualTreeColumn(Items[I]).SaveToStream(Stream);

    Stream.WriteBuffer(FPositionToIndex[0], Count * SizeOf(TColumnIndex));
  end;
  
  Stream.WriteBuffer(DefaultWidth, SizeOf(DefaultWidth));
end;

function TVirtualTreeColumns.TotalWidth: Integer;

var
  LastColumn: TColumnIndex;

begin
  Result := 0;
  if (Count > 0) and (Length(FPositionToIndex) > 0) then
  begin
    LastColumn := FPositionToIndex[Count - 1];
    if not (coVisible in Items[LastColumn].FOptions) then
      LastColumn := GetPreviousVisibleColumn(LastColumn);
    if LastColumn > NoColumn then
      with Items[LastColumn] do
        Result := FLeft + FWidth
  end;
end;

constructor TVTFixedAreaConstraints.Create(AOwner: TVTHeader);

begin
  inherited Create;

  FHeader := AOwner;
end;

procedure TVTFixedAreaConstraints.SetConstraints(Index: Integer; Value: TVTConstraintPercent);

begin
  case Index of
    0:
      if Value <> FMaxHeightPercent then
      begin
        FMaxHeightPercent := Value;
        if (Value > 0) and (Value < FMinHeightPercent) then
          FMinHeightPercent := Value;
        Change;
      end;
    1:
      if Value <> FMaxWidthPercent then
      begin
        FMaxWidthPercent := Value;
        if (Value > 0) and (Value < FMinWidthPercent) then
          FMinWidthPercent := Value;
        Change;
      end;
    2:
      if Value <> FMinHeightPercent then
      begin
        FMinHeightPercent := Value;
        if (FMaxHeightPercent > 0) and (Value > FMaxHeightPercent) then
          FMaxHeightPercent := Value;
        Change;
      end;
    3:
      if Value <> FMinWidthPercent then
      begin
        FMinWidthPercent := Value;
        if (FMaxWidthPercent > 0) and (Value > FMaxWidthPercent) then
          FMaxWidthPercent := Value;
        Change;
      end;
  end;
end;

procedure TVTFixedAreaConstraints.Change;

begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TVTFixedAreaConstraints.Assign(Source: TPersistent);

begin
  if Source is TVTFixedAreaConstraints then
  begin
    FMaxHeightPercent := TVTFixedAreaConstraints(Source).FMaxHeightPercent;
    FMaxWidthPercent := TVTFixedAreaConstraints(Source).FMaxWidthPercent;
    FMinHeightPercent := TVTFixedAreaConstraints(Source).FMinHeightPercent;
    FMinWidthPercent := TVTFixedAreaConstraints(Source).FMinWidthPercent;
    Change;
  end
  else
    inherited;
end;

constructor TVTHeader.Create(AOwner: TBaseVirtualTree);

begin
  inherited Create;
  FOwner := AOwner;
  FColumns := GetColumnsClass.Create(Self);
  FHeight := 19;
  FDefaultHeight := FHeight;
  FMinHeight := 10;
  FMaxHeight := 10000;
  FFont := TFont.Create;
  FFont.OnChange := FontChanged;
  FParentFont := False;
  FBackground := clBtnFace;
  FOptions := [hoColumnResize, hoDrag, hoShowSortGlyphs];

  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImageListChange;

  FSortColumn := NoColumn;
  FSortDirection := sdAscending;
  FMainColumn := NoColumn;

  FDragImage := TVTDragImage.Create(AOwner);
  with FDragImage do
  begin
    Fade := False;
    PostBlendBias := 0;
    PreBlendBias := -50;
    Transparency := 140;
  end;

  FFixedAreaConstraints := TVTFixedAreaConstraints.Create(Self);
  FFixedAreaConstraints.OnChange := FixedAreaConstraintsChanged;
end;

destructor TVTHeader.Destroy;

begin
  FDragImage.Free;
  FFixedAreaConstraints.Free;
  FImageChangeLink.Free;
  FFont.Free;
  FColumns.Clear; 
  FColumns.Free;
  inherited;
end;

procedure TVTHeader.FontChanged(Sender: TObject);
var
  i: Integer;
  lMaxHeight: Integer;
begin
  if toAutoChangeScale in Treeview.TreeOptions.AutoOptions then begin
    
    lMaxHeight := 0;
    for i:= 0 to Self.Columns.Count - 1 do
      lMaxHeight := Max(lMaxHeight, Columns[i].Spacing);
    
    With TBitmap.Create do
      try
        Canvas.Font.Assign(FFont);
        lMaxHeight := lMaxHeight  + (lMaxHeight div 2)  + Canvas.TextHeight('Q');
      finally
        Free;
      end;
    
    lMaxHeight := Max(lMaxHeight, fHeight);
    
    Self.SetHeight(lMaxHeight);
  end;
  Invalidate(nil);
end;

function TVTHeader.GetMainColumn: TColumnIndex;

begin
  if FColumns.Count > 0 then
    Result := FMainColumn
  else
    Result := NoColumn;
end;

function TVTHeader.GetUseColumns: Boolean;

begin
  Result := FColumns.Count > 0;
end;

function TVTHeader.IsFontStored: Boolean;

begin
  Result := not ParentFont;
end;

procedure TVTHeader.SetAutoSizeIndex(Value: TColumnIndex);

begin
  if FAutoSizeIndex <> Value then
  begin
    FAutoSizeIndex := Value;
    if hoAutoResize in FOptions then
      Columns.AdjustAutoSize(InvalidColumn);
  end;
end;

procedure TVTHeader.SetBackground(Value: TColor);

begin
  if FBackground <> Value then
  begin
    FBackground := Value;
    Invalidate(nil);
  end;
end;

procedure TVTHeader.SetColumns(Value: TVirtualTreeColumns);

begin
  FColumns.Assign(Value);
end;

procedure TVTHeader.SetDefaultHeight(Value: Integer);

begin
  if Value < FMinHeight then
    Value := FMinHeight;
  if Value > FMaxHeight then
    Value := FMaxHeight;

  if FHeight = FDefaultHeight then
    SetHeight(Value);
  FDefaultHeight := Value;
end;

procedure TVTHeader.SetFont(const Value: TFont);

begin
  FFont.Assign(Value);
  FParentFont := False;
end;

procedure TVTHeader.SetHeight(Value: Integer);

var
  RelativeMaxHeight,
  RelativeMinHeight,
  EffectiveMaxHeight,
  EffectiveMinHeight: Integer;

begin
  if not TreeView.HandleAllocated then
  begin
    FHeight := Value;
    Include(FStates, hsNeedScaling);
  end
  else
  begin
    with FFixedAreaConstraints do
    begin
      RelativeMaxHeight := ((Treeview.ClientHeight + FHeight) * FMaxHeightPercent) div 100;
      RelativeMinHeight := ((Treeview.ClientHeight + FHeight) * FMinHeightPercent) div 100;

      EffectiveMinHeight := IfThen(FMaxHeightPercent > 0, Min(RelativeMaxHeight, FMinHeight), FMinHeight);
      EffectiveMaxHeight := IfThen(FMinHeightPercent > 0, Max(RelativeMinHeight, FMaxHeight), FMaxHeight);

      Value := Min(Max(Value, EffectiveMinHeight), EffectiveMaxHeight);
      if FMinHeightPercent > 0 then
        Value := Max(RelativeMinHeight, Value);
      if FMaxHeightPercent > 0 then
        Value := Min(RelativeMaxHeight, Value);
    end;

    if FHeight <> Value then
    begin
      FHeight := Value;
      if not (csLoading in Treeview.ComponentState) and not (hsScaling in FStates) then
        RecalculateHeader;
      Treeview.Invalidate;
      UpdateWindow(Treeview.Handle);
    end;
  end;
end;

procedure TVTHeader.SetImages(const Value: TCustomImageList);

begin
  if FImages <> Value then
  begin
    if Assigned(FImages) then
    begin
      FImages.UnRegisterChanges(FImageChangeLink);
      FImages.RemoveFreeNotification(FOwner);
    end;
    FImages := Value;
    if Assigned(FImages) then
    begin
      FImages.RegisterChanges(FImageChangeLink);
      FImages.FreeNotification(FOwner);
    end;
    if not (csLoading in Treeview.ComponentState) then
      Invalidate(nil);
  end;
end;

procedure TVTHeader.SetMainColumn(Value: TColumnIndex);

begin
  if csLoading in Treeview.ComponentState then
    FMainColumn := Value
  else
  begin
    if Value < 0 then
      Value := 0;
    if Value > FColumns.Count - 1 then
      Value := FColumns.Count - 1;
    if Value <> FMainColumn then
    begin
      FMainColumn := Value;
      if not (csLoading in Treeview.ComponentState) then
      begin
        Treeview.MainColumnChanged;
        if not (toExtendedFocus in Treeview.FOptions.FSelectionOptions) then
          Treeview.FocusedColumn := FMainColumn;
        Treeview.Invalidate;
      end;
    end;
  end;
end;

procedure TVTHeader.SetMaxHeight(Value: Integer);

begin
  if Value < FMinHeight then
    Value := FMinHeight;
  FMaxHeight := Value;
  SetHeight(FHeight);
end;

procedure TVTHeader.SetMinHeight(Value: Integer);

begin
  if Value < 0 then
    Value := 0;
  if Value > FMaxHeight then
    Value := FMaxHeight;
  FMinHeight := Value;
  SetHeight(FHeight);
end;

procedure TVTHeader.SetOptions(Value: TVTHeaderOptions);

var
  ToBeSet,
  ToBeCleared: TVTHeaderOptions;

begin
  ToBeSet := Value - FOptions;
  ToBeCleared := FOptions - Value;
  FOptions := Value;

  if (hoAutoResize in (ToBeSet + ToBeCleared)) and (FColumns.Count > 0) then
  begin
    FColumns.AdjustAutoSize(InvalidColumn);
    if Treeview.HandleAllocated then
    begin
      Treeview.UpdateHorizontalScrollBar(False);
      if hoAutoResize in ToBeSet then
        Treeview.Invalidate;
    end;
  end;

  if not (csLoading in Treeview.ComponentState) and Treeview.HandleAllocated then
  begin
    if hoVisible in (ToBeSet + ToBeCleared) then
      RecalculateHeader;
    Invalidate(nil);
    Treeview.Invalidate;
  end;
end;

procedure TVTHeader.SetParentFont(Value: Boolean);

begin
  if FParentFont <> Value then
  begin
    FParentFont := Value;
    if FParentFont then
      FFont.Assign(FOwner.Font);
  end;
end;

procedure TVTHeader.SetSortColumn(Value: TColumnIndex);

begin
  if csLoading in Treeview.ComponentState then
    FSortColumn := Value
  else
    DoSetSortColumn(Value);
end;

procedure TVTHeader.SetSortDirection(const Value: TSortDirection);

begin
  if Value <> FSortDirection then
  begin
    FSortDirection := Value;
    Invalidate(nil);
    if ((toAutoSort in Treeview.FOptions.FAutoOptions) or (hoHeaderClickAutoSort in Options)) and (Treeview.FUpdateCount = 0) then
      Treeview.SortTree(FSortColumn, FSortDirection, True);
  end;
end;

function TVTHeader.CanSplitterResize(P: TPoint): Boolean;

begin
  Result := hoHeightResize in FOptions;
  DoCanSplitterResize(P, Result);
end;

procedure TVTHeader.SetStyle(Value: TVTHeaderStyle);

begin
  if FStyle <> Value then
  begin
    FStyle := Value;
    if not (csLoading in Treeview.ComponentState) then
      Invalidate(nil);
  end;
end;

function TVTHeader.CanWriteColumns: Boolean;

begin
  Result := True;
end;

procedure TVTHeader.ChangeScale(M, D: Integer);

begin
  
  if not ParentFont then
    FFont.Size := MulDiv(FFont.Size, M, D);
  Self.Height := MulDiv(fHeight, M, D);
  
end;

function TVTHeader.DetermineSplitterIndex(P: TPoint): Boolean;

var
  I,
  VisibleFixedWidth: Integer;
  SplitPoint: Integer;

  function IsNearBy(IsFixedCol: Boolean; LeftTolerance, RightTolerance: Integer): Boolean;

  begin
    if IsFixedCol then
      Result := (P.X < SplitPoint + Treeview.FEffectiveOffsetX + RightTolerance) and (P.X > SplitPoint + Treeview.FEffectiveOffsetX - LeftTolerance)
    else
      Result := (P.X > VisibleFixedWidth) and (P.X < SplitPoint + RightTolerance) and (P.X > SplitPoint - LeftTolerance);
  end;

begin
  Result := False;
  FColumns.FTrackIndex := NoColumn;

  VisibleFixedWidth := FColumns.GetVisibleFixedWidth;

  if FColumns.Count > 0 then
  begin
    if Treeview.UseRightToLeftAlignment then
    begin
      SplitPoint := -Treeview.FEffectiveOffsetX;
      if Integer(Treeview.FRangeX) < Treeview.ClientWidth then
        Inc(SplitPoint, Treeview.ClientWidth - Integer(Treeview.FRangeX));

      for I := 0 to FColumns.Count - 1 do
        with FColumns, Items[FPositionToIndex[I]] do
          if coVisible in FOptions then
          begin
            if IsNearBy(coFixed in FOptions, 5, 3) then
            begin
              if CanSplitterResize(P, FPositionToIndex[I]) then
              begin
                Result := True;
                FTrackIndex := FPositionToIndex[I];
                
                FTrackPoint.X := SplitPoint + IfThen(coFixed in FOptions, Treeview.FEffectiveOffsetX) + FWidth;
                FTrackPoint.Y := P.Y;
                Break;
              end;
            end;
            Inc(SplitPoint, FWidth);
          end;
    end
    else
    begin
      SplitPoint := -Treeview.FEffectiveOffsetX + Integer(Treeview.FRangeX);

      for I := FColumns.Count - 1 downto 0 do
        with FColumns, Items[FPositionToIndex[I]] do
          if coVisible in FOptions then
          begin
            if IsNearBy(coFixed in FOptions, 3, 5) then
            begin
              if CanSplitterResize(P, FPositionToIndex[I]) then
              begin
                Result := True;
                FTrackIndex := FPositionToIndex[I];
                
                FTrackPoint.X := SplitPoint + IfThen(coFixed in FOptions, Treeview.FEffectiveOffsetX) - FWidth;
                FTrackPoint.Y := P.Y;
                Break;
              end;
            end;
            Dec(SplitPoint, FWidth);
          end;
    end;
  end;
end;

procedure TVTHeader.DoAfterAutoFitColumn(Column: TColumnIndex);

begin
  if Assigned(TreeView.FOnAfterAutoFitColumn) then
    TreeView.FOnAfterAutoFitColumn(Self, Column);
end;

procedure TVTHeader.DoAfterColumnWidthTracking(Column: TColumnIndex);

begin
  if Assigned(TreeView.FOnAfterColumnWidthTracking) then
    TreeView.FOnAfterColumnWidthTracking(Self, Column);
end;

procedure TVTHeader.DoAfterHeightTracking;

begin
  if Assigned(TreeView.FOnAfterHeaderHeightTracking) then
    TreeView.FOnAfterHeaderHeightTracking(Self);
end;

function TVTHeader.DoBeforeAutoFitColumn(Column: TColumnIndex; SmartAutoFitType: TSmartAutoFitType): Boolean;

begin
  Result := True;
  if Assigned(TreeView.FOnBeforeAutoFitColumn) then
    TreeView.FOnBeforeAutoFitColumn(Self, Column, SmartAutoFitType, Result);
end;

procedure TVTHeader.DoBeforeColumnWidthTracking(Column: TColumnIndex; Shift: TShiftState);

begin
  if Assigned(TreeView.FOnBeforeColumnWidthTracking) then
    TreeView.FOnBeforeColumnWidthTracking(Self, Column, Shift);
end;

procedure TVTHeader.DoBeforeHeightTracking(Shift: TShiftState);

begin
  if Assigned(TreeView.FOnBeforeHeaderHeightTracking) then
    TreeView.FOnBeforeHeaderHeightTracking(Self, Shift);
end;

procedure TVTHeader.DoCanSplitterResize(P: TPoint; var Allowed: Boolean);
begin
  if Assigned(TreeView.FOnCanSplitterResizeHeader) then
    TreeView.FOnCanSplitterResizeHeader(Self, P, Allowed);
end;

function TVTHeader.DoColumnWidthDblClickResize(Column: TColumnIndex; P: TPoint; Shift: TShiftState): Boolean;

begin
  Result := True;
  if Assigned(TreeView.FOnColumnWidthDblClickResize) then
    TreeView.FOnColumnWidthDblClickResize(Self, Column, Shift, P, Result);
end;

function TVTHeader.DoColumnWidthTracking(Column: TColumnIndex; Shift: TShiftState; var TrackPoint: TPoint; P: TPoint): Boolean;

begin
  Result := True;
  if Assigned(TreeView.FOnColumnWidthTracking) then
    TreeView.FOnColumnWidthTracking(Self, Column, Shift, TrackPoint, P, Result);
end;

function TVTHeader.DoGetPopupMenu(Column: TColumnIndex; Position: TPoint): TPopupMenu;

var
  AskParent: Boolean;

begin
  Result := nil;
  if Assigned(TreeView.FOnGetPopupMenu) then
    TreeView.FOnGetPopupMenu(TreeView, nil, Column, Position, AskParent, Result);
end;

function TVTHeader.DoHeightTracking(var P: TPoint; Shift: TShiftState): Boolean;

begin
  Result := True;
  if Assigned(TreeView.FOnHeaderHeightTracking) then
    TreeView.FOnHeaderHeightTracking(Self, P, Shift, Result);
end;

function TVTHeader.DoHeightDblClickResize(var P: TPoint; Shift: TShiftState): Boolean;

begin
  Result := True;
  if Assigned(TreeView.FOnHeaderHeightDblClickResize) then
    TreeView.FOnHeaderHeightDblClickResize(Self, P, Shift, Result);
end;

procedure TVTHeader.DoSetSortColumn(Value: TColumnIndex);

begin
  if Value < NoColumn then
    Value := NoColumn;
  if Value > Columns.Count - 1 then
    Value := Columns.Count - 1;
  if FSortColumn <> Value then
  begin
    if FSortColumn > NoColumn then
      Invalidate(Columns[FSortColumn]);
    FSortColumn := Value;
    if FSortColumn > NoColumn then
      Invalidate(Columns[FSortColumn]);
    if ((toAutoSort in Treeview.FOptions.FAutoOptions) or (hoHeaderClickAutoSort in Options)) and (Treeview.FUpdateCount = 0) then
      Treeview.SortTree(FSortColumn, FSortDirection, True);
  end;
end;

procedure TVTHeader.DragTo(P: TPoint);

var
  I,
  NewTarget: Integer;
  
  ClientP: TPoint;
  Left,
  Right: Integer;
  NeedRepaint: Boolean; 

begin
  
  ClientP := Treeview.ScreenToClient(P);
  
  Inc(ClientP.Y, FHeight);
  NewTarget := FColumns.ColumnFromPosition(ClientP);
  NeedRepaint := (NewTarget <> InvalidColumn) and (NewTarget <> FColumns.FDropTarget);
  if NewTarget >= 0 then
  begin
    FColumns.GetColumnBounds(NewTarget, Left, Right);
    if (ClientP.X < ((Left + Right) div 2)) <> FColumns.FDropBefore then
    begin
      NeedRepaint := True;
      FColumns.FDropBefore := not FColumns.FDropBefore;
    end;
  end;

  if NeedRepaint then
  begin
    
    if FColumns.FDropTarget > NoColumn then
    begin
      I := FColumns.FDropTarget;
      FColumns.FDropTarget := NoColumn;
      Invalidate(FColumns.Items[I]);
    end;
    if (NewTarget > NoColumn) and (NewTarget <> FColumns.FDropTarget) then
    begin
      Invalidate(FColumns.Items[NewTarget]);
      FColumns.FDropTarget := NewTarget;
    end;
  end;

  FDragImage.DragTo(P, NeedRepaint);
end;

procedure TVTHeader.FixedAreaConstraintsChanged(Sender: TObject);

begin
  if Treeview.HandleAllocated then
    RescaleHeader
  else
    Include(FStates, hsNeedScaling);
end;

function TVTHeader.GetColumnsClass: TVirtualTreeColumnsClass;

begin
  Result := TVirtualTreeColumns;
end;

function TVTHeader.GetOwner: TPersistent;

begin
  Result := FOwner;
end;

function TVTHeader.GetShiftState: TShiftState;

begin
  Result := [];
  if GetKeyState(VK_SHIFT) < 0 then
    Include(Result, ssShift);
  if GetKeyState(VK_CONTROL) < 0 then
    Include(Result, ssCtrl);
  if GetKeyState(VK_MENU) < 0 then
    Include(Result, ssAlt);
end;

function TVTHeader.HandleHeaderMouseMove(var Message: TWMMouseMove): Boolean;

var
  P: TPoint;
  NextColumn,
  I: TColumnIndex;
  NewWidth: Integer;

begin
  Result := False;
  with Message do
  begin
    P := Point(XPos, YPos);
    if hsColumnWidthTrackPending in FStates then
    begin
      Treeview.StopTimer(HeaderTimer);
      FStates := FStates - [hsColumnWidthTrackPending] + [hsColumnWidthTracking];
      HandleHeaderMouseMove := True;
      Result := 0;
    end
    else
      if hsHeightTrackPending in FStates then
      begin
        Treeview.StopTimer(HeaderTimer);
        FStates := FStates - [hsHeightTrackPending] + [hsHeightTracking];
        HandleHeaderMouseMove := True;
        Result := 0;
      end
      else
        if hsColumnWidthTracking in FStates then
        begin
          if DoColumnWidthTracking(FColumns.FTrackIndex, GetShiftState, FTrackPoint, P) then
          begin
            if Treeview.UseRightToLeftAlignment then
            begin
              NewWidth := FTrackPoint.X - XPos;
              NextColumn := FColumns.GetPreviousVisibleColumn(FColumns.FTrackIndex);
          end
            else
            begin
              NewWidth := XPos - FTrackPoint.X;
              NextColumn := FColumns.GetNextVisibleColumn(FColumns.FTrackIndex);
            end;
            
            if (hoAutoResize in FOptions) and (FColumns.FTrackIndex = FAutoSizeIndex) and
               (NextColumn > NoColumn) and (coResizable in FColumns[NextColumn].FOptions) and
               (FColumns[FColumns.FTrackIndex].FMinWidth < NewWidth) and
               (FColumns[FColumns.FTrackIndex].FMaxWidth > NewWidth) then
              FColumns[NextColumn].Width := FColumns[NextColumn].Width - NewWidth
                                            + FColumns[FColumns.FTrackIndex].Width
            else
              FColumns[FColumns.FTrackIndex].Width := NewWidth; 
          end;
          HandleHeaderMouseMove := True;
          Result := 0;
        end
        else
          if hsHeightTracking in FStates then
          begin
            if DoHeightTracking(P, GetShiftState) then
              SetHeight(Integer(FHeight) + P.Y);
            HandleHeaderMouseMove := True;
            Result := 0;
          end
          else
          begin
            if hsDragPending in FStates then
            begin
              P := Treeview.ClientToScreen(P);
              
              if (hoDrag in FOptions) and Treeview.DoHeaderDragging(FColumns.FDownIndex) then
              begin
                if ((Abs(FDragStart.X - P.X) > Mouse.DragThreshold) or
                   (Abs(FDragStart.Y - P.Y) > Mouse.DragThreshold)) then
                begin
                  Treeview.StopTimer(HeaderTimer);
                  I := FColumns.FDownIndex;
                  FColumns.FDownIndex := NoColumn;
                  FColumns.FHoverIndex := NoColumn;
                  if I > NoColumn then
                    Invalidate(FColumns[I]);
                  PrepareDrag(P, FDragStart);
                  FStates := FStates - [hsDragPending] + [hsDragging];
                  HandleHeaderMouseMove := True;
                  Result := 0;
                end;
              end;
            end
            else
              if hsDragging in FStates then
              begin
                DragTo(Treeview.ClientToScreen(Point(XPos, YPos)));
                HandleHeaderMouseMove := True;
                Result := 0;
              end;
          end;
  end;
end;

function TVTHeader.HandleMessage(var Message: TMessage): Boolean;

var
  P: TPoint;
  R: TRect;
  I: TColumnIndex;
  OldPosition: Integer;
  HitIndex: TColumnIndex;
  NewCursor: HCURSOR;
  Button: TMouseButton;
  Menu: TPopupMenu;
  IsInHeader,
  IsHSplitterHit,
  IsVSplitterHit: Boolean;

  function HSPlitterHit: Boolean;

  var
    NextCol: TColumnIndex;

  begin
    Result := (hoColumnResize in FOptions) and DetermineSplitterIndex(P);
    if Result and not InHeader(P) then
    begin
      NextCol := FColumns.GetNextVisibleColumn(FColumns.FTrackIndex);
      if not (coFixed in FColumns[FColumns.FTrackIndex].Options) or (NextCol <= NoColumn) or
         (coFixed in FColumns[NextCol].Options) or (P.Y > Integer(Treeview.FRangeY)) then
        Result := False;
    end;
  end;

begin
  Result := False;
  case Message.Msg of
    WM_SIZE:
      begin
        if not (tsWindowCreating in FOwner.FStates) then
          if (hoAutoResize in FOptions) and not (hsAutoSizing in FStates) then
          begin
            FColumns.AdjustAutoSize(InvalidColumn);
            Invalidate(nil);
          end
          else
            if not (hsScaling in FStates) then
            begin
              RescaleHeader;
              Invalidate(nil);
            end;
      end;
    CM_PARENTFONTCHANGED:
      if FParentFont then
        FFont.Assign(FOwner.Font);
    CM_BIDIMODECHANGED:
      for I := 0 to FColumns.Count - 1 do
        if coParentBiDiMode in FColumns[I].FOptions then
          FColumns[I].ParentBiDiModeChanged;
    WM_NCMBUTTONDOWN:
      begin
        with TWMNCMButtonDown(Message) do
          P := Treeview.ScreenToClient(Point(XCursor, YCursor));
        if InHeader(P) then
          FOwner.DoHeaderMouseDown(mbMiddle, GetShiftState, P.X, P.Y + Integer(FHeight));
      end;
    WM_NCMBUTTONUP:
      begin
        with TWMNCMButtonUp(Message) do
          P := FOwner.ScreenToClient(Point(XCursor, YCursor));
        if InHeader(P) then
        begin
          FColumns.HandleClick(P, mbMiddle, True, False);
          FOwner.DoHeaderMouseUp(mbMiddle, GetShiftState, P.X, P.Y + Integer(FHeight));
          FColumns.FDownIndex := NoColumn;
          FColumns.FCheckBoxHit := False;
        end;
      end;
    WM_LBUTTONDBLCLK,
    WM_NCLBUTTONDBLCLK,
    WM_NCMBUTTONDBLCLK,
    WM_NCRBUTTONDBLCLK:
      begin
        if Message.Msg <> WM_LBUTTONDBLCLK then
          with TWMNCLButtonDblClk(Message) do
            P := FOwner.ScreenToClient(Point(XCursor, YCursor))
        else
          with TWMLButtonDblClk(Message) do
            P := Point(XPos, YPos);

        if (hoHeightDblClickResize in FOptions) and InHeaderSplitterArea(P) and (FDefaultHeight > 0) then
        begin
          if DoHeightDblClickResize(P, GetShiftState) and (FDefaultHeight > 0) then
            SetHeight(FMinHeight);
          Result := True;
        end
        else
          if HSplitterHit and ((Message.Msg = WM_NCLBUTTONDBLCLK) or (Message.Msg = WM_LBUTTONDBLCLK)) and
             (hoDblClickResize in FOptions) and (FColumns.FTrackIndex > NoColumn) then
          begin
            
            if DoColumnWidthDblClickResize(FColumns.FTrackIndex, P, GetShiftState) then
              AutoFitColumns(True, smaUseColumnOption, FColumns[FColumns.FTrackIndex].FPosition,
                             FColumns[FColumns.FTrackIndex].FPosition);
            Message.Result := 0;
            Result := True;
          end
          else
            if InHeader(P) and (Message.Msg <> WM_LBUTTONDBLCLK) then
            begin
              case Message.Msg of
                WM_NCMBUTTONDBLCLK:
                  Button := mbMiddle;
                WM_NCRBUTTONDBLCLK:
                  Button := mbRight;
                else
                  
                  Button := mbLeft;
              end;
              if Button = mbLeft then
                Columns.AdjustDownColumn(P);
              FColumns.HandleClick(P, Button, True, True);
            end;
      end;
    
    WM_LBUTTONDOWN,
    WM_NCLBUTTONDOWN:
      begin
        if (csDesigning in Treeview.ComponentState) and (Message.Msg = WM_LBUTTONDOWN) then
          Exit;

        Application.CancelHint;
        
        Treeview.StopTimer(ScrollTimer);
        Treeview.DoStateChange([], [tsScrollPending, tsScrolling]);
        
        Treeview.StopTimer(EditTimer);
        Treeview.DoStateChange([], [tsEditPending]);

        if Message.Msg = WM_LBUTTONDOWN then
          
          with TWMLButtonDown(Message) do
            P := Point(XPos, YPos)
        else
          with TWMNCLButtonDown(Message) do
          begin
            
            FDragStart := Point(XCursor, YCursor);
            P := Treeview.ScreenToClient(FDragStart);
          end;

        IsInHeader := InHeader(P);
        IsVSplitterHit := InHeaderSplitterArea(P) and CanSplitterResize(P);
        IsHSplitterHit := HSplitterHit;

        if IsVSplitterHit or IsHSplitterHit then
        begin
          FTrackStart := P;
          FColumns.FHoverIndex := NoColumn;
          if IsVSplitterHit then
          begin
            DoBeforeHeightTracking(GetShiftState);
            Include(FStates, hsHeightTrackPending)
          end
          else
          begin
            DoBeforeColumnWidthTracking(FColumns.FTrackIndex, GetShiftState);
            Include(FStates, hsColumnWidthTrackPending);
          end;

          SetCapture(Treeview.Handle);
          Result := True;
          Message.Result := 0;
        end
        else
          if IsInHeader then
          begin
            HitIndex := Columns.AdjustDownColumn(P);
            if (hoDrag in FOptions) and (HitIndex > NoColumn) and (coDraggable in FColumns[HitIndex].FOptions) then
            begin
              
              Include(FStates, hsDragPending);
              SetCapture(Treeview.Handle);
              Result := True;
              Message.Result := 0;
            end;
          end;
        
        if IsInHeader then
          FOwner.DoHeaderMouseDown(mbLeft, GetShiftState, P.X, P.Y + Integer(FHeight));
      end;
    WM_NCRBUTTONDOWN:
      begin
        with TWMNCRButtonDown(Message) do
          P := FOwner.ScreenToClient(Point(XCursor, YCursor));
        if InHeader(P) then
          FOwner.DoHeaderMouseDown(mbRight, GetShiftState, P.X, P.Y + Integer(FHeight));
      end;
    WM_NCRBUTTONUP:
      if not (csDesigning in FOwner.ComponentState) then
        with TWMNCRButtonUp(Message) do
        begin
          Application.CancelHint;

          P := FOwner.ScreenToClient(Point(XCursor, YCursor));
          if InHeader(P) then
          begin
            FColumns.HandleClick(P, mbRight, True, False);
            FOwner.DoHeaderMouseUp(mbRight, GetShiftState, P.X, P.Y + Integer(FHeight));
            FColumns.FDownIndex := NoColumn;
            FColumns.FTrackIndex := NoColumn;
            FColumns.FCheckBoxHit := False;

            Menu := FPopupMenu;
            if not Assigned(Menu) then
              Menu := DoGetPopupMenu(FColumns.ColumnFromPosition(Point(P.X, P.Y + Integer(FHeight))), P);
            
            if Assigned(Menu) then
            begin
              Treeview.StopTimer(ScrollTimer);
              Treeview.StopTimer(HeaderTimer);
              FColumns.FHoverIndex := NoColumn;
              Treeview.DoStateChange([], [tsScrollPending, tsScrolling]);
              Menu.PopupComponent := Treeview;
              Menu.Popup(XCursor, YCursor);
              HandleMessage := True;
            end;
          end;
        end;
    
    WM_LBUTTONUP,
    WM_NCLBUTTONUP:
      begin
        Application.CancelHint;

        if FStates <> [] then
        begin
          ReleaseCapture;
          if hsDragging in FStates then
          begin
            
            with TWMLButtonUp(Message) do
              P := Treeview.ClientToScreen(Point(XPos, YPos));
            GetWindowRect(Treeview.Handle, R);
            with FColumns do
            begin
              FDragImage.EndDrag;
              if (FDropTarget > -1) and (FDropTarget <> FDragIndex) and PtInRect(R, P) then
              begin
                OldPosition := FColumns[FDragIndex].Position;
                if FColumns.FDropBefore then
                begin
                  if FColumns[FDragIndex].Position < FColumns[FDropTarget].Position then
                    FColumns[FDragIndex].Position := Max(0, FColumns[FDropTarget].Position - 1)
                  else
                    FColumns[FDragIndex].Position := FColumns[FDropTarget].Position;
                end
                else
                begin
                  if FColumns[FDragIndex].Position < FColumns[FDropTarget].Position then
                    FColumns[FDragIndex].Position := FColumns[FDropTarget].Position
                  else
                    FColumns[FDragIndex].Position := FColumns[FDropTarget].Position + 1;
                end;
                Treeview.DoHeaderDragged(FDragIndex, OldPosition);
              end
              else
                Treeview.DoHeaderDraggedOut(FDragIndex, P);
              FDropTarget := NoColumn;
            end;
            Invalidate(nil);
          end;
          Result := True;
          Message.Result := 0;
        end;

        case Message.Msg of
          WM_LBUTTONUP:
            with TWMLButtonUp(Message) do
            begin
              if FColumns.FDownIndex > NoColumn then
                FColumns.HandleClick(Point(XPos, YPos), mbLeft, False, False);
              if FStates <> [] then
                FOwner.DoHeaderMouseUp(mbLeft, KeysToShiftState(Keys), XPos, YPos);
            end;
          WM_NCLBUTTONUP:
            with TWMNCLButtonUp(Message) do
            begin
              P := FOwner.ScreenToClient(Point(XCursor, YCursor));
              FColumns.HandleClick(P, mbLeft, False, False);
              FOwner.DoHeaderMouseUp(mbLeft, GetShiftState, P.X, P.Y + Integer(FHeight));
            end;
        end;

        if FColumns.FTrackIndex > NoColumn then
        begin
          if hsColumnWidthTracking in FStates then
            DoAfterColumnWidthTracking(FColumns.FTrackIndex);
          Invalidate(Columns[FColumns.FTrackIndex]);
          FColumns.FTrackIndex := NoColumn;
        end;
        if FColumns.FDownIndex > NoColumn then
        begin
          Invalidate(Columns[FColumns.FDownIndex]);
          FColumns.FDownIndex := NoColumn;
        end;
        if hsHeightTracking in FStates then
          DoAfterHeightTracking;

        FStates := FStates - [hsDragging, hsDragPending,
                              hsColumnWidthTracking, hsColumnWidthTrackPending,
                              hsHeightTracking, hsHeightTrackPending];
      end;
    
    WM_NCMOUSEMOVE:
      with TWMNCMouseMove(Message), FColumns do
      begin
        P := Treeview.ScreenToClient(Point(XCursor, YCursor));
        Treeview.DoHeaderMouseMove(GetShiftState, P.X, P.Y + Integer(FHeight));
        if InHeader(P) and ((AdjustHoverColumn(P)) or ((FDownIndex >= 0) and (FHoverIndex <> FDownIndex))) then
        begin
          
          Treeview.StopTimer(HeaderTimer);
          SetTimer(Treeview.Handle, HeaderTimer, 50, nil);
          
          if hoShowHint in FOptions then
          begin
            
            XCursor := P.x;
            YCursor := P.y + Integer(FHeight);
            Application.HintMouseMessage(Treeview, Message);
          end;
        end
      end;
    WM_TIMER:
      if TWMTimer(Message).TimerID = HeaderTimer then
      begin
        
        GetCursorPos(P);
        P := Treeview.ScreenToClient(P);
        with FColumns do
        begin
          if not InHeader(P) or ((FDownIndex > NoColumn) and (FHoverIndex <> FDownIndex)) then
          begin
            Treeview.StopTimer(HeaderTimer);
            FHoverIndex := NoColumn;
            FClickIndex := NoColumn;
            FDownIndex := NoColumn;
            FCheckBoxHit := False;
            Result := True;
            Message.Result := 0;
            Invalidate(nil);
          end;
        end;
      end;
    WM_MOUSEMOVE: 
      Result := HandleHeaderMouseMove(TWMMouseMove(Message));
    WM_SETCURSOR:
      if not (csDesigning in FOwner.ComponentState) and (FStates = []) then
      begin
        
        GetCursorPos(P);
        
        P := Treeview.ScreenToClient(P);
        IsHSplitterHit := HSplitterHit;
        IsVSplitterHit := InHeaderSplitterArea(P) and CanSplitterResize(P);

        if IsVSplitterHit or IsHSplitterHit then
        begin
          NewCursor := Screen.Cursors[Treeview.Cursor];
          if IsVSplitterHit and (hoHeightResize in FOptions) then
            NewCursor := Screen.Cursors[crVertSplit]
          else
            if IsHSplitterHit then
              NewCursor := Screen.Cursors[crHeaderSplit];

          Treeview.DoGetHeaderCursor(NewCursor);
          Result := NewCursor <> Screen.Cursors[crDefault];
          if Result then
          begin
            Windows.SetCursor(NewCursor);
            Message.Result := 1;
          end
        end;
      end
      else
      begin
        Message.Result := 1;
        Result := True;
      end;
    WM_KEYDOWN,
    WM_KILLFOCUS:
      if (Message.Msg = WM_KILLFOCUS) or
         (TWMKeyDown(Message).CharCode = VK_ESCAPE) then
      begin
        if hsDragging in FStates then
        begin
          ReleaseCapture;
          FDragImage.EndDrag;
          Exclude(FStates, hsDragging);
          FColumns.FDropTarget := NoColumn;
          Invalidate(nil);
          Result := True;
          Message.Result := 0;
        end
        else
        begin
          if [hsColumnWidthTracking, hsHeightTracking] * FStates <> [] then
          begin
            ReleaseCapture;
            if hsColumnWidthTracking in FStates then
              DoAfterColumnWidthTracking(FColumns.FTrackIndex);
            if hsHeightTracking in FStates then
              DoAfterHeightTracking;
            Result := True;
            Message.Result := 0;
          end;

          FStates := FStates - [hsColumnWidthTracking, hsColumnWidthTrackPending,
                                hsHeightTracking, hsHeightTrackPending];
        end;
      end;
  end;
end;

procedure TVTHeader.ImageListChange(Sender: TObject);

begin
  if not (csDestroying in Treeview.ComponentState) then
    Invalidate(nil);
end;

procedure TVTHeader.PrepareDrag(P, Start: TPoint);

var
  Image: TBitmap;
  ImagePos: TPoint;
  DragColumn: TVirtualTreeColumn;
  RTLOffset: Integer;

begin
  
  FColumns.FDropTarget := NoColumn;
  Start := Treeview.ScreenToClient(Start);
  Inc(Start.Y, FHeight);
  FColumns.FDragIndex := FColumns.ColumnFromPosition(Start);
  DragColumn := FColumns[FColumns.FDragIndex];

  Image := TBitmap.Create;
  with Image do
  try
    PixelFormat := pf32Bit;
    Width := DragColumn.Width;
    Height := FHeight;
    
    Canvas.Brush.Color := clBtnFace;
    Canvas.FillRect(Rect(0, 0, Width, Height));

    if TreeView.UseRightToLeftAlignment then
      RTLOffset := Treeview.ComputeRTLOffset
    else
      RTLOffset := 0;
    with DragColumn do
      FColumns.PaintHeader(Canvas, Rect(FLeft, 0, FLeft + Width, Height), Point(-RTLOffset, 0), RTLOffset);

    if Treeview.UseRightToLeftAlignment then
      ImagePos := Treeview.ClientToScreen(Point(DragColumn.Left + Treeview.ComputeRTLOffset(True), 0))
    else
      ImagePos := Treeview.ClientToScreen(Point(DragColumn.Left, 0));
    
    Dec(ImagePos.Y, FHeight);

    if hoRestrictDrag in FOptions then
      FDragImage.MoveRestriction := dmrHorizontalOnly
    else
      FDragImage.MoveRestriction := dmrNone;
    FDragImage.PrepareDrag(Image, ImagePos, P, nil);
    FDragImage.ShowDragImage;
  finally
    Image.Free;
  end;
end;

procedure TVTHeader.ReadColumns(Reader: TReader);

begin
  Include(FStates, hsLoading);
  Columns.Clear;
  Reader.ReadValue;
  Reader.ReadCollection(Columns);
  Exclude(FStates, hsLoading);
end;

procedure TVTHeader.RecalculateHeader;

begin
  if Treeview.HandleAllocated then
  begin
    Treeview.UpdateHeaderRect;
    SetWindowPos(Treeview.Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOACTIVATE or SWP_NOOWNERZORDER or
      SWP_NOSENDCHANGING or SWP_NOSIZE or SWP_NOZORDER);
  end;
end;

procedure TVTHeader.RescaleHeader;

var
  FixedWidth,
  MaxFixedWidth,
  MinFixedWidth: Integer;

  procedure ComputeConstraints;

  var
    I: TColumnIndex;

  begin
    with FColumns do
    begin
      I := GetFirstVisibleColumn;
      while I > NoColumn do
      begin
        if (coFixed in FColumns[I].Options) and (FColumns[I].Width < FColumns[I].MinWidth) then
          FColumns[I].FWidth := FColumns[I].FMinWidth;
        I := GetNextVisibleColumn(I);
      end;
      FixedWidth := GetVisibleFixedWidth;
    end;

    with FFixedAreaConstraints do
    begin
      MinFixedWidth := (TreeView.ClientWidth * FMinWidthPercent) div 100;
      MaxFixedWidth := (TreeView.ClientWidth * FMaxWidthPercent) div 100;
    end;
  end;

begin
  if ([csLoading, csReading, csWriting, csDestroying] * Treeview.ComponentState = []) and not
     (hsLoading in FStates) and Treeview.HandleAllocated then
  begin
    Include(FStates, hsScaling);

    SetHeight(FHeight);
    RecalculateHeader;

    with FFixedAreaConstraints do
      if (FMinHeightPercent > 0) or (FMaxHeightPercent > 0) then
      begin
        ComputeConstraints;

        with FColumns do
          if (FMaxWidthPercent > 0) and (FixedWidth > MaxFixedWidth) then
            ResizeColumns(MaxFixedWidth - FixedWidth, 0, Count - 1, [coVisible, coFixed])
          else
            if (FMinWidthPercent > 0) and (FixedWidth < MinFixedWidth) then
              ResizeColumns(MinFixedWidth - FixedWidth, 0, Count - 1, [coVisible, coFixed]);

        FColumns.UpdatePositions;
      end;

    Exclude(FStates, hsScaling);
    Exclude(FStates, hsNeedScaling);
  end;
end;

procedure TVTHeader.UpdateMainColumn;

begin
  if FMainColumn < 0 then
    FMainColumn := 0;
  if FMainColumn > FColumns.Count - 1 then
    FMainColumn := FColumns.Count - 1;
end;

procedure TVTHeader.UpdateSpringColumns;

var
  I: TColumnIndex;
  SpringCount: Integer;
  Sign: Integer;
  ChangeBy: Single;
  Difference: Single;
  NewAccumulator: Single;

begin
  with TreeView do
    ChangeBy := FHeaderRect.Right - FHeaderRect.Left - FLastWidth;
  if (hoAutoSpring in FOptions) and (FLastWidth <> 0) and (ChangeBy <> 0) then
  begin
    
    if ChangeBy < 0 then
      Sign := -1
    else
      Sign := 1;
    ChangeBy := Abs(ChangeBy);
    
    SpringCount := 0;
    for I := 0 to FColumns.Count-1 do
      if [coVisible, coAutoSpring] * FColumns[I].FOptions = [coVisible, coAutoSpring] then
        Inc(SpringCount);
    if SpringCount > 0 then
    begin
      
      Difference := ChangeBy / SpringCount;
      
      for I := 0 to FColumns.Count - 1 do
        if [coVisible, coAutoSpring] * FColumns[I].FOptions = [coVisible, coAutoSpring] then
        begin
          
          NewAccumulator := FColumns[I].FSpringRest + Difference;
          
          if NewAccumulator >= 1 then
            FColumns[I].SetWidth(FColumns[I].FWidth + (Trunc(NewAccumulator) * Sign));
          FColumns[I].FSpringRest := Frac(NewAccumulator);
          
          ChangeBy := ChangeBy - Difference;
          
          if ChangeBy < 0 then
            Break;
        end;
    end;
  end;
  with TreeView do
    FLastWidth := FHeaderRect.Right - FHeaderRect.Left;
end;

type
  
  {$hints off}
  TWriterHack = class(TFiler)
  private
    FRootAncestor: TComponent;
    FPropPath: string;
  end;
  {$hints on}

procedure TVTHeader.WriteColumns(Writer: TWriter);

var
  LastPropPath: String;

begin
  
  LastPropPath := TWriterHack(Writer).FPropPath;
  try
    
    TWriterHack(Writer).FPropPath := '';
    Writer.WriteCollection(Columns);
  finally
    TWriterHack(Writer).FPropPath := LastPropPath;
  end;
end;

function TVTHeader.AllowFocus(ColumnIndex: TColumnIndex): Boolean;
begin
  Result := False;
  if not FColumns.IsValidColumn(ColumnIndex) then exit; 

  Result := (coAllowFocus in FColumns[ColumnIndex].Options);
end;

procedure TVTHeader.Assign(Source: TPersistent);

begin
  if Source is TVTHeader then
  begin
    AutoSizeIndex := TVTHeader(Source).AutoSizeIndex;
    Background := TVTHeader(Source).Background;
    Columns := TVTHeader(Source).Columns;
    Font := TVTHeader(Source).Font;
    FixedAreaConstraints.Assign(TVTHeader(Source).FixedAreaConstraints);
    Height := TVTHeader(Source).Height;
    Images := TVTHeader(Source).Images;
    MainColumn := TVTHeader(Source).MainColumn;
    Options := TVTHeader(Source).Options;
    ParentFont := TVTHeader(Source).ParentFont;
    PopupMenu := TVTHeader(Source).PopupMenu;
    SortColumn := TVTHeader(Source).SortColumn;
    SortDirection := TVTHeader(Source).SortDirection;
    Style := TVTHeader(Source).Style;

    RescaleHeader;
  end
  else
    inherited;
end;

procedure TVTHeader.AutoFitColumns(Animated: Boolean = True; SmartAutoFitType: TSmartAutoFitType = smaUseColumnOption;
  RangeStartCol: Integer = NoColumn; RangeEndCol: Integer = NoColumn);

  function GetUseSmartColumnWidth(ColumnIndex: TColumnIndex): Boolean;

  begin
    Result := False;
    case SmartAutoFitType of
      smaAllColumns:
        Result := True;
      smaNoColumn:
        Result := False;
      smaUseColumnOption:
        Result := coSmartResize in FColumns.Items[ColumnIndex].FOptions;
    end;
  end;

  procedure DoAutoFitColumn(Column: TColumnIndex);

  begin
    with FColumns do
      if ([coResizable, coVisible] * Items[FPositionToIndex[Column]].FOptions = [coResizable, coVisible]) and
            DoBeforeAutoFitColumn(FPositionToIndex[Column], SmartAutoFitType) and not TreeView.OperationCanceled then
      begin
        if Animated then
          AnimatedResize(FPositionToIndex[Column], Treeview.GetMaxColumnWidth(FPositionToIndex[Column],
            GetUseSmartColumnWidth(FPositionToIndex[Column])))
        else
          FColumns[FPositionToIndex[Column]].Width := Treeview.GetMaxColumnWidth(FPositionToIndex[Column],
            GetUseSmartColumnWidth(FPositionToIndex[Column]));

        DoAfterAutoFitColumn(FPositionToIndex[Column]);
      end;
  end;

var
  I: Integer;
  StartCol,
  EndCol: Integer;

begin
  StartCol := Max(NoColumn + 1, RangeStartCol);

  if RangeEndCol <= NoColumn then
    EndCol := FColumns.Count - 1
  else
    EndCol := Min(RangeEndCol, FColumns.Count - 1);

  if StartCol > EndCol then
    Exit; 

  TreeView.StartOperation(okAutoFitColumns);
  try
    if Assigned(TreeView.FOnBeforeAutoFitColumns) then
      TreeView.FOnBeforeAutoFitColumns(Self, SmartAutoFitType);

    for I := StartCol to EndCol do
      DoAutoFitColumn(I);

    if Assigned(TreeView.FOnAfterAutoFitColumns) then
      TreeView.FOnAfterAutoFitColumns(Self);

  finally
    Treeview.EndOperation(okAutoFitColumns);
  end;
end;

function TVTHeader.InHeader(P: TPoint): Boolean;

var
  R, RW: TRect;

begin
  R := Treeview.FHeaderRect;
  
  GetWindowRect(Treeview.Handle, RW);
  
  MapWindowPoints(0, Treeview.Handle, RW, 2);
  
  OffsetRect(R, RW.Left, RW.Top);
  Result := PtInRect(R, P);
end;

function TVTHeader.InHeaderSplitterArea(P: TPoint): Boolean;

var
  R, RW: TRect;

begin
  if (P.Y > 2) or (P.Y < -2) or not (hoVisible in FOptions) then
    Result := False
  else
  begin
    R := Treeview.FHeaderRect;
    Inc(R.Bottom, 2);
    
    GetWindowRect(Treeview.Handle, RW);
    
    MapWindowPoints(0, Treeview.Handle, RW, 2);
    
    OffsetRect(R, RW.Left, RW.Top);
    Result := PtInRect(R, P);
  end;
end;

procedure TVTHeader.Invalidate(Column: TVirtualTreeColumn; ExpandToBorder: Boolean = False);

var
  R, RW: TRect;

begin
  if (hoVisible in FOptions) and Treeview.HandleAllocated then
    with Treeview do
    begin
      if Column = nil then
        R := FHeaderRect
      else
      begin
        R := Column.GetRect;
        if not (coFixed in Column.Options) then
          OffsetRect(R, -FEffectiveOffsetX, 0);
        if UseRightToLeftAlignment then
          OffsetRect(R, ComputeRTLOffset, 0);
        if ExpandToBorder then
        begin
          if (hoFullRepaintOnResize in FHeader.FOptions) then
          begin
            R.Left := FHeaderRect.Left;
            R.Right := FHeaderRect.Right;
          end else
          begin
            if UseRightToLeftAlignment then
              R.Left := FHeaderRect.Left
            else
              R.Right := FHeaderRect.Right;
          end;
        end;
      end;
      
      GetWindowRect(Handle, RW);
      
      OffsetRect(R, RW.Left, RW.Top);
      
      MapWindowPoints(0, Handle, R, 2);
      RedrawWindow(Handle, @R, 0, RDW_FRAME or RDW_INVALIDATE or RDW_VALIDATE or RDW_NOINTERNALPAINT or
        RDW_NOERASE or RDW_NOCHILDREN);
    end;
end;

procedure TVTHeader.LoadFromStream(const Stream: TStream);

var
  Dummy,
  Version: Integer;
  S: AnsiString;
  OldOptions: TVTHeaderOptions;

begin
  Include(FStates, hsLoading);
  with Stream do
  try
    
    OldOptions := FOptions;
    FOptions := [];
    
    ReadBuffer(Dummy, SizeOf(Dummy));
    if Dummy > -1 then
    begin
      
      Seek(-SizeOf(Dummy), soFromCurrent);
      Version := -1;
    end
    else 
      ReadBuffer(Version, SizeOf(Version));
    Columns.LoadFromStream(Stream, Version);

    ReadBuffer(Dummy, SizeOf(Dummy));
    AutoSizeIndex := Dummy;
    ReadBuffer(Dummy, SizeOf(Dummy));
    Background := Dummy;
    ReadBuffer(Dummy, SizeOf(Dummy));
    Height := Dummy;
    ReadBuffer(Dummy, SizeOf(Dummy));
    FOptions := OldOptions;
    Options := TVTHeaderOptions(Dummy);
    
    ReadBuffer(Dummy, SizeOf(Dummy));
    Style := TVTHeaderStyle(Dummy);
    
    with Font do
    begin
      ReadBuffer(Dummy, SizeOf(Dummy));
      Color := Dummy;
      ReadBuffer(Dummy, SizeOf(Dummy));
      Height := Dummy;
      ReadBuffer(Dummy, SizeOf(Dummy));
      SetLength(S, Dummy);
      ReadBuffer(PAnsiChar(S)^, Dummy);
      if VTHeaderStreamVersion >= 4 then
        {$if CompilerVersion >= 20}
        Name := UTF8ToString(S)
        {$else}
        Name := UTF8Decode(S)
        {$ifend}
      else
        Name := S;
      ReadBuffer(Dummy, SizeOf(Dummy));
      Pitch := TFontPitch(Dummy);
      ReadBuffer(Dummy, SizeOf(Dummy));
      Style := TFontStyles(Byte(Dummy));
    end;
    
    if Version > 0 then
    begin
      ReadBuffer(Dummy, SizeOf(Dummy));
      MainColumn := Dummy;
      ReadBuffer(Dummy, SizeOf(Dummy));
      SortColumn := Dummy;
      ReadBuffer(Dummy, SizeOf(Dummy));
      SortDirection := TSortDirection(Byte(Dummy));
    end;
    
    if Version > 4 then
    begin
      ReadBuffer(Dummy, SizeOf(Dummy));
      ParentFont := Boolean(Dummy);
      ReadBuffer(Dummy, SizeOf(Dummy));
      FMaxHeight := Integer(Dummy);
      ReadBuffer(Dummy, SizeOf(Dummy));
      FMinHeight := Integer(Dummy);
      ReadBuffer(Dummy, SizeOf(Dummy));
      FDefaultHeight := Integer(Dummy);
      with FFixedAreaConstraints do
      begin
        ReadBuffer(Dummy, SizeOf(Dummy));
        FMaxHeightPercent := TVTConstraintPercent(Dummy);
        ReadBuffer(Dummy, Sizeof(Dummy));
        FMaxWidthPercent := TVTConstraintPercent(Dummy);
        ReadBuffer(Dummy, SizeOf(Dummy));
        FMinHeightPercent := TVTConstraintPercent(Dummy);
        ReadBuffer(Dummy, Sizeof(Dummy));
        FMinWidthPercent := TVTConstraintPercent(Dummy);
      end
    end;
  finally
    Exclude(FStates, hsLoading);
    Treeview.DoColumnResize(NoColumn);
  end;
end;

function TVTHeader.ResizeColumns(ChangeBy: Integer; RangeStartCol: TColumnIndex; RangeEndCol: TColumnIndex;
  Options: TVTColumnOptions = [coVisible]): Integer;

var
  Start,
  I: TColumnIndex;
  ColCount,
  ToGo,
  Sign,
  Rest,
  MaxDelta,
  Difference: Integer;
  Constraints,
  Widths: Array of Integer;
  BonusPixel: Boolean;

  function IsResizable (Column: TColumnIndex): Boolean;

  begin
    if BonusPixel then
      Result := Widths[Column - RangeStartCol] < Constraints[Column - RangeStartCol]
    else
      Result := Widths[Column - RangeStartCol] > Constraints[Column - RangeStartCol];
  end;

  procedure IncDelta(Column: TColumnIndex);

  begin
    if BonusPixel then
      Inc(MaxDelta, FColumns[Column].MaxWidth - Widths[Column - RangeStartCol])
    else
      Inc(MaxDelta, Widths[Column - RangeStartCol] - Constraints[Column - RangeStartCol]);
  end;

  function ChangeWidth(Column: TColumnIndex; Delta: Integer): Integer;

  begin
    if Delta > 0 then
      Delta := Min(Delta, Constraints[Column - RangeStartCol] - Widths[Column - RangeStartCol])
    else
      Delta := Max(Delta, Constraints[Column - RangeStartCol] - Widths[Column - RangeStartCol]);

    Inc(Widths[Column - RangeStartCol], Delta);
    Dec(ToGo, Abs(Delta));
    Result := Abs(Delta);
  end;

  function ReduceConstraints: Boolean;

  var
    MaxWidth,
    MaxReserveCol,
    Column: TColumnIndex;

  begin
    Result := True;
    if not (hsScaling in FStates) or BonusPixel then
      Exit;

    MaxWidth := 0;
    MaxReserveCol := NoColumn;
    for Column := RangeStartCol to RangeEndCol do
      if (Options * FColumns[Column].FOptions = Options) and
         (FColumns[Column].FWidth > MaxWidth) then
      begin
        MaxWidth := Widths[Column - RangeStartCol];
        MaxReserveCol := Column;
      end;

    if (MaxReserveCol <= NoColumn) or (Constraints[MaxReserveCol - RangeStartCol] <= 10) then
      Result := False
    else
      Dec(Constraints[MaxReserveCol - RangeStartCol],
          Constraints[MaxReserveCol - RangeStartCol] div 10);
  end;

begin
  Result := 0;
  if ChangeBy <> 0 then
  begin
    
    BonusPixel := ChangeBy > 0;
    Sign := IfThen(BonusPixel, 1, -1);
    Start := IfThen(BonusPixel, RangeStartCol, RangeEndCol);
    ToGo := Abs(ChangeBy);
    SetLength(Widths, RangeEndCol - RangeStartCol + 1);
    SetLength(Constraints, RangeEndCol - RangeStartCol + 1);
    for I := RangeStartCol to RangeEndCol do
    begin
      Widths[I - RangeStartCol] := FColumns[I].FWidth;
      Constraints[I - RangeStartCol] := IfThen(BonusPixel, FColumns[I].MaxWidth, FColumns[I].MinWidth);
    end;

    repeat
      repeat
        MaxDelta := 0;
        ColCount := 0;
        for I := RangeStartCol to RangeEndCol do
          if (Options * FColumns[I].FOptions = Options) and IsResizable(I) then
          begin
            Inc(ColCount);
            IncDelta(I);
          end;
        if MaxDelta < Abs(ChangeBy) then
          if not ReduceConstraints then
            Break;
      until (MaxDelta >= Abs(ChangeBy)) or not (hsScaling in FStates);

      if ColCount = 0 then
        Break;

      ToGo := Min(ToGo, MaxDelta);
      Difference := ToGo div ColCount;
      Rest := ToGo mod ColCount;

      if Difference > 0 then
        for I := RangeStartCol to RangeEndCol do
          if (Options * FColumns[I].FOptions = Options) and IsResizable(I) then
            ChangeWidth(I, Difference * Sign);
      
      I := Start;
      while Rest > 0 do
      begin
        if (Options * FColumns[I].FOptions = Options) and IsResizable(I) then
          if FColumns[I].FBonusPixel <> BonusPixel then
          begin
            Dec(Rest, ChangeWidth(I, Sign));
            FColumns[I].FBonusPixel := BonusPixel;
          end;
        Inc(I, Sign);
        if (BonusPixel and (I > RangeEndCol)) or (not BonusPixel and (I < RangeStartCol)) then
        begin
          for I := RangeStartCol to RangeEndCol do
            if Options * FColumns[I].FOptions = Options then
              FColumns[I].FBonusPixel := not FColumns[I].FBonusPixel;
          I := Start;
        end;
      end;
    until ToGo <= 0;
    
    Include(FStates, hsResizing);
    for I := RangeStartCol to RangeEndCol do
      if (Options * FColumns[I].FOptions = Options) then
      begin
        Inc(Result, Widths[I - RangeStartCol] - FColumns[I].FWidth);
        FColumns[I].SetWidth(Widths[I - RangeStartCol]);
      end;
    Exclude(FStates, hsResizing);
  end;
end;

procedure TVTHeader.RestoreColumns;

var
  I: TColumnIndex;

begin
  with FColumns do
    for I := Count - 1 downto 0 do
      if [coResizable, coVisible] * Items[FPositionToIndex[I]].FOptions = [coResizable, coVisible] then
        Items[I].RestoreLastWidth;
end;

procedure TVTHeader.SaveToStream(const Stream: TStream);

var
  Dummy: Integer;
  Tmp: AnsiString;

begin
  with Stream do
  begin
    
    Dummy := -1;
    WriteBuffer(Dummy, SizeOf(Dummy));
    
    Dummy := VTHeaderStreamVersion;
    WriteBuffer(Dummy, SizeOf(Dummy));
    
    Columns.SaveToStream(Stream);

    Dummy := FAutoSizeIndex;
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := FBackground;
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := FHeight;
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := Integer(FOptions);
    WriteBuffer(Dummy, SizeOf(Dummy));
    
    Dummy := Ord(FStyle);
    WriteBuffer(Dummy, SizeOf(Dummy));
    
    with Font do
    begin
      Dummy := Color;
      WriteBuffer(Dummy, SizeOf(Dummy));
      
      Dummy := Height;
      WriteBuffer(Dummy, SizeOf(Dummy));
      Tmp := UTF8Encode(Name);
      Dummy := Length(Tmp);
      WriteBuffer(Dummy, SizeOf(Dummy));
      WriteBuffer(PAnsiChar(Tmp)^, Dummy);
      Dummy := Ord(Pitch);
      WriteBuffer(Dummy, SizeOf(Dummy));
      Dummy := Byte(Style);
      WriteBuffer(Dummy, SizeOf(Dummy));
    end;
    
    Dummy := FMainColumn;
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := FSortColumn;
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := Byte(FSortDirection);
    WriteBuffer(Dummy, SizeOf(Dummy));
    
    Dummy := Integer(ParentFont);
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := Integer(FMaxHeight);
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := Integer(FMinHeight);
    WriteBuffer(Dummy, SizeOf(Dummy));
    Dummy := Integer(FDefaultHeight);
    WriteBuffer(Dummy, SizeOf(Dummy));
    with FFixedAreaConstraints do
    begin
      Dummy := Integer(FMaxHeightPercent);
      WriteBuffer(Dummy, SizeOf(Dummy));
      Dummy := Integer(FMaxWidthPercent);
      WriteBuffer(Dummy, SizeOf(Dummy));
      Dummy := Integer(FMinHeightPercent);
      WriteBuffer(Dummy, SizeOf(Dummy));
      Dummy := Integer(FMinWidthPercent);
      WriteBuffer(Dummy, SizeOf(Dummy));
    end
  end;
end;

constructor TScrollBarOptions.Create(AOwner: TBaseVirtualTree);

begin
  inherited Create;

  FOwner := AOwner;
  FAlwaysVisible := False;
  FScrollBarStyle := sbmRegular;
  FScrollBars := ssBoth;
  FIncrementX := 20;
  FIncrementY := 20;
end;

procedure TScrollBarOptions.SetAlwaysVisible(Value: Boolean);

begin
  if FAlwaysVisible <> Value then
  begin
    FAlwaysVisible := Value;
    if not (csLoading in FOwner.ComponentState) and FOwner.HandleAllocated then
      FOwner.RecreateWnd;
  end;
end;

procedure TScrollBarOptions.SetScrollBars(Value: TScrollStyle);

begin
  if FScrollbars <> Value then
  begin
    FScrollBars := Value;
    if not (csLoading in FOwner.ComponentState) and FOwner.HandleAllocated then
      FOwner.RecreateWnd;
  end;
end;

procedure TScrollBarOptions.SetScrollBarStyle(Value: TScrollBarStyle);

begin
  if FScrollBarStyle <> Value then
  begin
    FScrollBarStyle := Value;
  end;
end;

function TScrollBarOptions.GetOwner: TPersistent;

begin
  Result := FOwner;
end;

procedure TScrollBarOptions.Assign(Source: TPersistent);

begin
  if Source is TScrollBarOptions then
  begin
    AlwaysVisible := TScrollBarOptions(Source).AlwaysVisible;
    HorizontalIncrement := TScrollBarOptions(Source).HorizontalIncrement;
    ScrollBars := TScrollBarOptions(Source).ScrollBars;
    ScrollBarStyle := TScrollBarOptions(Source).ScrollBarStyle;
    VerticalIncrement := TScrollBarOptions(Source).VerticalIncrement;
  end
  else
    inherited;
end;

constructor TVTColors.Create(AOwner: TBaseVirtualTree);

begin
  FOwner := AOwner;
  FColors[0] := clBtnShadow;      
  FColors[1] := clHighlight;      
  FColors[2] := clHighLight;      
  FColors[3] := clHighLight;      
  FColors[4] := clBtnFace;        
  FColors[5] := clBtnShadow;      
  FColors[6] := clBtnFace;        
  FColors[7] := clBtnFace;        
  FColors[8] := clWindowText;     
  FColors[9] := clHighLight;      
  FColors[10] := clBtnFace;       
  FColors[11] := clHighlight;     
  FColors[12] := clHighlight;     
  FColors[13] := clHighlight;     
  FColors[14] := clBtnShadow;     
  FColors[15] := clHighlightText; 
end;

function TVTColors.GetBackgroundColor: TColor;
begin

{$IF CompilerVersion >= 23 }
  if FOwner.VclStyleEnabled then
    Result := StyleServices.GetStyleColor(scTreeView)
  else
{$IFEND}
    Result := FOwner.Color;
end;

function TVTColors.GetColor(const Index: Integer): TColor;

begin
{$IF CompilerVersion >= 23 }
  if FOwner.VclStyleEnabled then
  begin
    case Index of
      0:
        StyleServices.GetElementColor(StyleServices.GetElementDetails(ttItemDisabled), ecTextColor, Result); 
      1:
        Result := StyleServices.GetSystemColor(clHighlight); 
      2:
        Result := StyleServices.GetSystemColor(clHighlight); 
      3:
        Result := StyleServices.GetSystemColor(clHighlight); 
      4:
        Result := StyleServices.GetSystemColor(clBtnFace); 
      5:
        StyleServices.GetElementColor(StyleServices.GetElementDetails(ttBranch), ecBorderColor, Result); 
      6:
        Result := StyleServices.GetSystemColor(clHighlight); 
      7:
        Result := StyleServices.GetSystemColor(clBtnFace); 
      8:
        if not StyleServices.GetElementColor(StyleServices.GetElementDetails(ttItemHot), ecTextColor, Result) or
          (Result <> clWindowText) then
          Result := NodeFontColor; 
      9:
        StyleServices.GetElementColor(StyleServices.GetElementDetails(ttItemSelected), ecFillColor, Result);
      
      10:
        Result := StyleServices.GetSystemColor(clHighlight); 
      11:
        Result := StyleServices.GetSystemColor(clBtnFace); 
      12:
        Result := StyleServices.GetSystemColor(clHighlight); 
      13:
        Result := StyleServices.GetSystemColor(clHighlight); 
      14:
        StyleServices.GetElementColor(StyleServices.GetElementDetails(thHeaderItemNormal), ecTextColor, Result); 
      15:
        if not StyleServices.GetElementColor(StyleServices.GetElementDetails(ttItemSelected), ecTextColor, Result) or
          (Result <> clWindowText) then
          Result := NodeFontColor; 
    end;
  end
  else
{$IFEND}
  Result := FColors[Index];
end;

function TVTColors.GetHeaderFontColor: TColor;
begin

{$IF CompilerVersion >= 23 }
  if FOwner.VclStyleEnabled then
    StyleServices.GetElementColor(StyleServices.GetElementDetails(thHeaderItemNormal), ecTextColor, Result)
  else
{$IFEND}
    Result := FOwner.FHeader.Font.Color;
end;

function TVTColors.GetNodeFontColor: TColor;
begin
{$IF CompilerVersion >= 23 }
  if FOwner.VclStyleEnabled then
    StyleServices.GetElementColor(StyleServices.GetElementDetails(ttItemNormal), ecTextColor, Result)
  else
{$IFEND}
    Result := FOwner.Font.Color;
end;

procedure TVTColors.SetColor(const Index: Integer; const Value: TColor);

begin
  if FColors[Index] <> Value then
  begin
    FColors[Index] := Value;
    if not (csLoading in FOwner.ComponentState) and FOwner.HandleAllocated then
    begin
      
      case Index of
        5:
          begin
            FOwner.PrepareBitmaps(True, False);
            FOwner.Invalidate;
          end;
        7:
          RedrawWindow(FOwner.Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_NOERASE or RDW_NOCHILDREN)
      else
        FOwner.Invalidate;
      end;
    end;
  end;
end;

procedure TVTColors.Assign(Source: TPersistent);

begin
  if Source is TVTColors then
  begin
    FColors := TVTColors(Source).FColors;
    if FOwner.FUpdateCount = 0 then
      FOwner.Invalidate;
  end
  else
    inherited;
end;

constructor TClipboardFormats.Create(AOwner: TBaseVirtualTree);

begin
  FOwner := AOwner;
  Sorted := True;
  Duplicates := dupIgnore;
end;

function TClipboardFormats.Add(const S: string): Integer;

var
  Format: Word;
  RegisteredClass: TVirtualTreeClass;

begin
  RegisteredClass := InternalClipboardFormats.FindFormat(S, Format);
  if Assigned(RegisteredClass) and FOwner.ClassType.InheritsFrom(RegisteredClass) then
    Result := inherited Add(S)
  else
    Result := -1;
end;

procedure TClipboardFormats.Insert(Index: Integer; const S: string);

var
  Format: Word;
  RegisteredClass: TVirtualTreeClass;

begin
  RegisteredClass := InternalClipboardFormats.FindFormat(S, Format);
  if Assigned(RegisteredClass) and FOwner.ClassType.InheritsFrom(RegisteredClass) then
    inherited Insert(Index, S);
end;

constructor TBaseVirtualTree.Create(AOwner: TComponent);

begin
  if not Initialized then
    InitializeGlobalStructures;

  inherited;

  ControlStyle := ControlStyle - [csSetCaption] + [csCaptureMouse, csOpaque, csReplicatable, csDisplayDragImage,
    csReflector];
  FTotalInternalDataSize := 0;
  FNodeDataSize := -1;
  Width := 200;
  Height := 100;
  TabStop := True;
  ParentColor := False;
  FDefaultNodeHeight := 18;
  FDragOperations := [doCopy, doMove];
  FHotCursor := crDefault;
  FScrollBarOptions := TScrollBarOptions.Create(Self);
  FFocusedColumn := NoColumn;
  FDragImageKind := diComplete;
  FLastSelectionLevel := -1;
  FAnimationType := hatSystemDefault;
  FSelectionBlendFactor := 128;

  FIndent := 18;

  FPlusBM := TBitmap.Create;
  FHotPlusBM := TBitmap.Create;
  FMinusBM := TBitmap.Create;
  FHotMinusBM := TBitmap.Create;

  FBorderStyle := bsSingle;
  FButtonStyle := bsRectangle;
  FButtonFillMode := fmTreeColor;

  FHeader := GetHeaderClass.Create(Self);
  
  inherited DoubleBuffered := False;

  FCheckImageKind := ckSystemDefault;
  FCheckImages := SystemCheckImages;

  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImageListChange;
  FStateChangeLink := TChangeLink.Create;
  FStateChangeLink.OnChange := ImageListChange;
  FCustomCheckChangeLink := TChangeLink.Create;
  FCustomCheckChangeLink.OnChange := ImageListChange;

  FAutoExpandDelay := 1000;
  FAutoScrollDelay := 1000;
  FAutoScrollInterval := 1;

  FBackground := TPicture.Create;

  FDefaultPasteMode := amAddChildLast;
  FMargin := 4;
  FTextMargin := 4;
  FLastDragEffect := DROPEFFECT_NONE;
  FDragType := dtOLE;
  FDragHeight := 350;
  FDragWidth := 200;

  FColors := TVTColors.Create(Self);
  FEditDelay := 1000;

  FDragImage := TVTDragImage.Create(Self);
  with FDragImage do
  begin
    Fade := True;
    PostBlendBias := 0;
    PreBlendBias := 0;
    Transparency := 200;
  end;

  SetLength(FSingletonNodeArray, 1);
  FAnimationDuration := 200;
  FSearchTimeout := 1000;
  FSearchStart := ssFocusedNode;
  FNodeAlignment := naProportional;
  FLineStyle := lsDotted;
  FIncrementalSearch := isNone;
  FClipboardFormats := TClipboardFormats.Create(Self);
  FOptions := GetOptionsClass.Create(Self);

  AddThreadReference;

  FVclStyleEnabled := False;
  
  {$if CompilerVersion >= 23 }
  FSetOrRestoreBevelKindAndBevelWidth := False;
  FSavedBevelKind := bkNone;
  FSavedBorderWidth := 0;
  {$ifend}
end;

destructor TBaseVirtualTree.Destroy;

begin
  InterruptValidation();
  Exclude(FOptions.FMiscOptions, toReadOnly);
  ReleaseThreadReference(Self);
  StopWheelPanning;
  CancelEditNode;
  
  FEditLink := nil;
  FClipboardFormats.Free;
  
  Clear;
  FDragImage.Free;
  FColors.Free;
  FBackground.Free;
  FImageChangeLink.Free;
  FStateChangeLink.Free;
  FCustomCheckChangeLink.Free;
  FScrollBarOptions.Free;
  
  if HandleAllocated then
    DestroyWindowHandle;
  
  if FDottedBrush <> 0 then
    DeleteObject(FDottedBrush);
  FDottedBrush := 0;

  FOptions.Free; 
  FHeader.Free;
  FHeader := nil;

  FreeMem(FRoot);

  FPlusBM.Free;
  FHotPlusBM.Free;
  FMinusBM.Free;
  FHotMinusBM.Free;

  inherited;
end;

procedure TBaseVirtualTree.AdjustCoordinatesByIndent(var PaintInfo: TVTPaintInfo; Indent: Integer);

var
  Offset: Integer;

begin
  with PaintInfo do
  begin
    Offset := Indent * Integer(FIndent);
    if BidiMode = bdLeftToRight then
    begin
      Inc(ContentRect.Left, Offset);
      Inc(ImageInfo[iiNormal].XPos, Offset);
      Inc(ImageInfo[iiState].XPos, Offset);
      Inc(ImageInfo[iiCheck].XPos, Offset);
    end
    else
    begin
      Dec(ContentRect.Right, Offset);
      Dec(ImageInfo[iiNormal].XPos, Offset);
      Dec(ImageInfo[iiState].XPos, Offset);
      Dec(ImageInfo[iiCheck].XPos, Offset);
    end;
  end;
end;

procedure TBaseVirtualTree.AdjustTotalCount(Node: PVirtualNode; Value: Integer; relative: Boolean = False);

var
  Difference: Integer;
  Run: PVirtualNode;

begin
  if relative then
    Difference := Value
  else
    Difference := Value - Integer(Node.TotalCount);
  if Difference <> 0 then
  begin
    Run := Node;
    
    while Assigned(Run) and (Run <> Pointer(Self)) do
    begin
      Inc(Integer(Run.TotalCount), Difference);
      Run := Run.Parent;
    end;
  end;
end;

procedure TBaseVirtualTree.AdjustTotalHeight(Node: PVirtualNode; Value: Integer; relative: Boolean = False);

var
  Difference: Integer;
  Run: PVirtualNode;

begin
  if relative then
    Difference := Value
  else
    Difference := Value - Integer(Node.TotalHeight);
  if Difference <> 0 then
  begin
    Run := Node;
    repeat
      Inc(Integer(Run.TotalHeight), Difference);
      
      if not (vsVisible in Run.States) or (Run = FRoot) or
        (Run.Parent = nil) or not (vsExpanded in Run.Parent.States) then
        Break;

      Run := Run.Parent;
    until False;
  end;

  UpdateVerticalRange;
end;

function TBaseVirtualTree.CalculateCacheEntryCount: Integer;

begin
  if FVisibleCount > 1 then
    Result := Ceil(FVisibleCount / CacheThreshold)
  else
    Result := 0;
end;

procedure TBaseVirtualTree.CalculateVerticalAlignments(ShowImages, ShowStateImages: Boolean; Node: PVirtualNode;
  var VAlign, VButtonAlign: Integer);

begin
  
  case FNodeAlignment of
    naFromTop:
      VAlign := Node.Align;
    naFromBottom:
      VAlign := Integer(NodeHeight[Node]) - Node.Align;
  else 
    
    if ShowImages or ShowStateImages then
    begin
      if ShowImages then
        VAlign := GetNodeImageSize(Node).cy
      else
        VAlign := FStateImages.Height;
      VAlign := MulDiv((Integer(NodeHeight[Node]) - VAlign), Node.Align, 100) + VAlign div 2;
    end
    else
      if toShowButtons in FOptions.FPaintOptions then
        VAlign := MulDiv((Integer(NodeHeight[Node]) - FPlusBM.Height), Node.Align, 100) + FPlusBM.Height div 2
      else
        VAlign := MulDiv(Integer(Node.NodeHeight), Node.Align, 100);
  end;

  VButtonAlign := VAlign - FPlusBM.Height div 2 - (FPlusBM.Height and 1);
end;

function TBaseVirtualTree.ChangeCheckState(Node: PVirtualNode; Value: TCheckState): Boolean;

var
  Run: PVirtualNode;
  UncheckedCount,
  MixedCheckCount,
  CheckedCount: Cardinal;

begin
  Result := not (vsChecking in Node.States);
  with Node^ do
  if Result then
  begin
    Include(States, vsChecking);
    if not (vsInitialized in States) then
      InitNode(Node);
    
    if FCheckPropagationCount = 0 then 
      DoStateChange([tsCheckPropagation]);
    Inc(FCheckPropagationCount); 
    
    case CheckType of
      
      ctTriStateCheckBox:
        begin
          
          if toAutoTristateTracking in FOptions.FAutoOptions then
            case Value of
              csUncheckedNormal:
                if Node.ChildCount > 0 then
                begin
                  Run := FirstChild;
                  CheckedCount := 0;
                  MixedCheckCount := 0;
                  UncheckedCount := 0;
                  while Assigned(Run) do
                  begin
                    if Run.CheckType in [ctCheckBox, ctTriStateCheckBox] then
                    begin
                      SetCheckState(Run, csUncheckedNormal);
                      
                      case Run.CheckState of
                        csCheckedNormal:
                          Inc(CheckedCount);
                        csMixedNormal:
                          Inc(MixedCheckCount);
                        csUncheckedNormal:
                          Inc(UncheckedCount);
                      end;
                    end;
                    Run := Run.NextSibling;
                  end;
                  
                  if MixedCheckCount > 0 then
                    Value := csMixedNormal
                  else
                    
                    if CheckedCount > 0 then
                      if UncheckedCount > 0 then
                        Value := csMixedNormal
                      else
                        Value := csCheckedNormal;
                end;
              csCheckedNormal:
                if Node.ChildCount > 0 then
                begin
                  Run := FirstChild;
                  CheckedCount := 0;
                  MixedCheckCount := 0;
                  UncheckedCount := 0;
                  while Assigned(Run) do
                  begin
                    if Run.CheckType in [ctCheckBox, ctTriStateCheckBox] then
                    begin
                      SetCheckState(Run, csCheckedNormal);
                      
                      case Run.CheckState of
                        csCheckedNormal:
                          Inc(CheckedCount);
                        csMixedNormal:
                          Inc(MixedCheckCount);
                        csUncheckedNormal:
                          Inc(UncheckedCount);
                      end;
                    end;
                    Run := Run.NextSibling;
                  end;
                  
                  if MixedCheckCount > 0 then
                    Value := csMixedNormal
                  else
                    
                    if CheckedCount > 0 then
                      if UncheckedCount > 0 then
                        Value := csMixedNormal
                      else
                        Value := csCheckedNormal;
                end;
            end;
        end;
      
      ctRadioButton:
        if Value = csCheckedNormal then
        begin
          Value := csCheckedNormal;
          
          Run := Parent.FirstChild;
          while Assigned(Run) do
          begin
            if Run.CheckType = ctRadioButton then
              Run.CheckState := csUncheckedNormal;
            Run := Run.NextSibling;
          end;
          Invalidate;
        end;
    end;

    if Result then
      CheckState := Value 
    else
      CheckState := UnpressedState[CheckState]; 
    
    if not (vsInitialized in Parent.States) then
      InitNode(Parent);
    if (toAutoTristateTracking in FOptions.FAutoOptions) and ([vsChecking, vsDisabled] * Parent.States = []) and
      (CheckType in [ctCheckBox, ctTriStateCheckBox]) and (Parent <> FRoot) and
      (Parent.CheckType = ctTriStateCheckBox) then
      Result := CheckParentCheckState(Node, Value)
    else
      Result := True;

    InvalidateNode(Node);
    Exclude(States, vsChecking);

    Dec(FCheckPropagationCount); 
    if FCheckPropagationCount = 0 then 
      DoStateChange([], [tsCheckPropagation]);
  end;
end;

function TBaseVirtualTree.CollectSelectedNodesLTR(MainColumn, NodeLeft, NodeRight: Integer; Alignment: TAlignment;
  OldRect, NewRect: TRect): Boolean;

var
  Run,
  NextNode: PVirtualNode;
  TextRight,
  TextLeft,
  CheckOffset,
  CurrentTop,
  CurrentRight,
  NextTop,
  NextColumn,
  NodeWidth,
  Dummy: Integer;
  MinY, MaxY: Integer;
  StateImageOffset: Integer;
  IsInOldRect,
  IsInNewRect: Boolean;
  
  WithCheck,
  WithImages,
  WithStateImages,
  DoSwitch,
  AutoSpan: Boolean;
  SimpleSelection: Boolean;

begin
  
  Result := False;
  
  MinY := Min(OldRect.Top, NewRect.Top);
  MaxY := Max(OldRect.Bottom, NewRect.Bottom);
  
  DoSwitch := ssCtrl in FDrawSelShiftState;
  WithCheck := (toCheckSupport in FOptions.FMiscOptions) and Assigned(FCheckImages);
  
  WithImages := Assigned(FImages);
  WithStateImages := Assigned(FStateImages);
  if WithStateImages then
    StateImageOffset := FStateImages.Width + 2
  else
    StateImageOffset := 0;
  if WithCheck then
    CheckOffset := FCheckImages.Width + 2
  else
    CheckOffset := 0;
  AutoSpan := FHeader.UseColumns and (toAutoSpanColumns in FOptions.FAutoOptions);
  SimpleSelection := toSimpleDrawSelection in FOptions.FSelectionOptions;
  
  Run := GetNodeAt(0, MinY, False, CurrentTop);

  if Assigned(Run) then
  begin
    
    if toShowRoot in FOptions.FPaintOptions then
      Inc(NodeLeft, Integer((GetNodeLevel(Run) + 1) * FIndent) + FMargin)    else
      Inc(NodeLeft, Integer(GetNodeLevel(Run) * FIndent) + FMargin);
    
    repeat
      
      TextLeft := NodeLeft;
      if WithCheck and (Run.CheckType <> ctNone) then
        Inc(TextLeft, CheckOffset);
      if WithImages and HasImage(Run, ikNormal, MainColumn) then
        Inc(TextLeft, GetNodeImageSize(run).cx + 2);
      if WithStateImages and HasImage(Run, ikState, MainColumn) then
        Inc(TextLeft, StateImageOffset);
      NextTop := CurrentTop + Integer(NodeHeight[Run]);
      
      if SimpleSelection or (toFullRowSelect in FOptions.FSelectionOptions) then
      begin
        IsInOldRect := (NextTop > OldRect.Top) and (CurrentTop < OldRect.Bottom) and
          ((FHeader.Columns.Count = 0) or (FHeader.Columns.TotalWidth > OldRect.Left)) and (NodeLeft < OldRect.Right);
        IsInNewRect := (NextTop > NewRect.Top) and (CurrentTop < NewRect.Bottom) and
          ((FHeader.Columns.Count = 0) or (FHeader.Columns.TotalWidth > NewRect.Left)) and (NodeLeft < NewRect.Right);
      end
      else
      begin
        
        if AutoSpan then
        begin
          with FHeader.FColumns do
          begin
            NextColumn := MainColumn;
            repeat
              Dummy := GetNextVisibleColumn(NextColumn);
              if (Dummy = InvalidColumn) or not ColumnIsEmpty(Run, Dummy) or
                 (Items[Dummy].BidiMode <> bdLeftToRight) then
                Break;
              NextColumn := Dummy;
            until False;
            if NextColumn = MainColumn then
              CurrentRight := NodeRight
            else
              GetColumnBounds(NextColumn, Dummy, CurrentRight);
          end;
        end
        else
          CurrentRight := NodeRight;
          
          if (TextLeft < OldRect.Left) or (TextLeft < NewRect.Left) or (Alignment <> taLeftJustify) then
          begin
            NodeWidth := DoGetNodeWidth(Run, MainColumn);
            if NodeWidth >= (CurrentRight - TextLeft) then
              TextRight := CurrentRight
            else
              case Alignment of
                taLeftJustify:
                  TextRight := TextLeft + NodeWidth;
                taCenter:
                  begin
                    TextLeft := (TextLeft + CurrentRight - NodeWidth) div 2;
                    TextRight := TextLeft + NodeWidth;
                  end;
              else
                
                TextRight := CurrentRight;
                TextLeft := TextRight - NodeWidth;
              end;
          end
          else
            TextRight := CurrentRight;
        
        IsInOldRect := (OldRect.Left <= TextRight) and (OldRect.Right >= TextLeft) and
          (NextTop > OldRect.Top) and (CurrentTop < OldRect.Bottom);
        IsInNewRect := (NewRect.Left <= TextRight) and (NewRect.Right >= TextLeft) and
          (NextTop > NewRect.Top) and (CurrentTop < NewRect.Bottom);
      end;

      if IsInOldRect xor IsInNewRect then
      begin
        Result := True;
        if DoSwitch then
        begin
          if vsSelected in Run.States then
            InternalRemoveFromSelection(Run)
          else
            InternalCacheNode(Run);
        end
        else
        begin
          if IsInNewRect then
            InternalCacheNode(Run)
          else
            InternalRemoveFromSelection(Run);
          end;
      end;
      CurrentTop := NextTop;
      
      NextNode := GetNextVisibleNoInit(Run, True);
      if NextNode = nil then
        Break;
      Inc(NodeLeft, CountLevelDifference(Run, NextNode) * Integer(FIndent));
      Run := NextNode;
    until CurrentTop > MaxY;
  end;
end;

function TBaseVirtualTree.CollectSelectedNodesRTL(MainColumn, NodeLeft, NodeRight: Integer; Alignment: TAlignment;
  OldRect, NewRect: TRect): Boolean;

var
  Run,
  NextNode: PVirtualNode;
  TextRight,
  TextLeft,
  CheckOffset,
  CurrentTop,
  CurrentLeft,
  NextTop,
  NextColumn,
  NodeWidth,
  Dummy: Integer;
  MinY, MaxY: Integer;
  StateImageOffset: Integer;
  IsInOldRect,
  IsInNewRect: Boolean;
  
  WithCheck,
  WithImages,
  WithStateImages,
  DoSwitch,
  AutoSpan: Boolean;
  SimpleSelection: Boolean;

begin
  
  Result := False;
  
  ChangeBiDiModeAlignment(Alignment);
  
  MinY := Min(OldRect.Top, NewRect.Top);
  MaxY := Max(OldRect.Bottom, NewRect.Bottom);
  
  DoSwitch := ssCtrl in FDrawSelShiftState;
  WithCheck := (toCheckSupport in FOptions.FMiscOptions) and Assigned(FCheckImages);
  
  WithImages := Assigned(FImages);
  WithStateImages := Assigned(FStateImages);
  if WithStateImages then
    StateImageOffset := FStateImages.Width + 2
  else
    StateImageOffset := 0;
  if WithCheck then
    CheckOffset := FCheckImages.Width + 2
  else
    CheckOffset := 0;
  AutoSpan := FHeader.UseColumns and (toAutoSpanColumns in FOptions.FAutoOptions);
  SimpleSelection := toSimpleDrawSelection in FOptions.FSelectionOptions;
  
  Run := GetNodeAt(0, MinY, False, CurrentTop);

  if Assigned(Run) then
  begin
    
    if toShowRoot in FOptions.FPaintOptions then
      Dec(NodeRight, Integer((GetNodeLevel(Run) + 1) * FIndent) + FMargin)    else
      Dec(NodeRight, Integer(GetNodeLevel(Run) * FIndent) + FMargin);
    
    repeat
      
      TextRight := NodeRight;
      if WithCheck and (Run.CheckType <> ctNone) then
        Dec(TextRight, CheckOffset);
      if WithImages and HasImage(Run, ikNormal, MainColumn) then
        Dec(TextRight, GetNodeImageSize(run).cx + 2);
      if WithStateImages and HasImage(Run, ikState, MainColumn) then
        Dec(TextRight, StateImageOffset);
      NextTop := CurrentTop + Integer(NodeHeight[Run]);
      
      if SimpleSelection then
      begin
        IsInOldRect := (NextTop > OldRect.Top) and (CurrentTop < OldRect.Bottom);
        IsInNewRect := (NextTop > NewRect.Top) and (CurrentTop < NewRect.Bottom);
      end
      else
      begin        
        if AutoSpan then
        begin
          NextColumn := MainColumn;
          repeat
            Dummy := FHeader.FColumns.GetPreviousVisibleColumn(NextColumn);
            if (Dummy = InvalidColumn) or not ColumnIsEmpty(Run, Dummy) or
               (FHeader.FColumns[Dummy].BiDiMode = bdLeftToRight) then
              Break;
            NextColumn := Dummy;
          until False;
          if NextColumn = MainColumn then
            CurrentLeft := NodeLeft
          else
            FHeader.FColumns.GetColumnBounds(NextColumn, CurrentLeft, Dummy);
        end
        else
          CurrentLeft := NodeLeft;
          
          if (TextRight > OldRect.Right) or (TextRight > NewRect.Right) or (Alignment <> taRightJustify) then
          begin
          NodeWidth := DoGetNodeWidth(Run, MainColumn);
          if NodeWidth >= (TextRight - CurrentLeft) then
            TextLeft := CurrentLeft
          else
            case Alignment of
              taLeftJustify:
                begin
                  TextLeft := CurrentLeft;
                  TextRight := TextLeft + NodeWidth;
                end;
              taCenter:
                begin
                  TextLeft := (TextRight + CurrentLeft - NodeWidth) div 2;
                  TextRight := TextLeft + NodeWidth;
                end;
              else
                
                TextLeft := TextRight - NodeWidth;
            end;
        end
        else
          TextLeft := CurrentLeft;
        
        IsInOldRect := (OldRect.Right >= TextLeft) and (OldRect.Left <= TextRight) and
          (NextTop > OldRect.Top) and (CurrentTop < OldRect.Bottom);
        IsInNewRect := (NewRect.Right >= TextLeft) and (NewRect.Left <= TextRight) and
          (NextTop > NewRect.Top) and (CurrentTop < NewRect.Bottom);
      end;

      if IsInOldRect xor IsInNewRect then
      begin
        Result := True;
        if DoSwitch then
        begin
          if vsSelected in Run.States then
            InternalRemoveFromSelection(Run)
          else
            InternalCacheNode(Run);
        end
        else
        begin
          if IsInNewRect then
            InternalCacheNode(Run)
          else
            InternalRemoveFromSelection(Run);
        end;
      end;
      CurrentTop := NextTop;
      
      NextNode := GetNextVisibleNoInit(Run, True);
      if NextNode = nil then
        Break;
      Dec(NodeRight, CountLevelDifference(Run, NextNode) * Integer(FIndent));
      Run := NextNode;
    until CurrentTop > MaxY;
  end;
end;

procedure TBaseVirtualTree.ClearNodeBackground(const PaintInfo: TVTPaintInfo; UseBackground, Floating: Boolean;
  R: TRect);

var
  BackColor: TColor;
  EraseAction: TItemEraseAction;
  Offset: TPoint;

begin
  BackColor := FColors.BackGroundColor;
  with PaintInfo do
  begin
    EraseAction := eaDefault;

    if Floating then
    begin
      Offset := Point(-FEffectiveOffsetX, R.Top);
      OffsetRect(R, 0, -Offset.Y);
    end
    else
      Offset := Point(0, 0);

    DoBeforeItemErase(Canvas, Node, R, Backcolor, EraseAction);

    with Canvas do
    begin
      case EraseAction of
        eaNone:
          ;
        eaColor:
          begin
            
            Brush.Color := BackColor;
            FillRect(R);
          end;
      else 
        if UseBackground then
        begin
          if toStaticBackground in TreeOptions.PaintOptions then
            StaticBackground(FBackground.Bitmap, Canvas, Offset, R)
          else
            TileBackground(FBackground.Bitmap, Canvas, Offset, R);
        end
        else
        begin
          if (poDrawSelection in PaintOptions) and (toFullRowSelect in FOptions.FSelectionOptions) and
             (vsSelected in Node.States) and not (toUseBlendedSelection in FOptions.PaintOptions) and not
             (tsUseExplorerTheme in FStates) then
          begin
            if toShowHorzGridLines in FOptions.PaintOptions then
              Dec(R.Bottom);
            if Focused or (toPopupMode in FOptions.FPaintOptions) then
            begin
              Brush.Color := FColors.FocusedSelectionColor;
              Pen.Color := FColors.FocusedSelectionBorderColor;
            end
            else
            begin
              Brush.Color := FColors.UnfocusedSelectionColor;
              Pen.Color := FColors.UnfocusedSelectionBorderColor;
            end;

            with TWithSafeRect(R) do
              RoundRect(Left, Top, Right, Bottom, FSelectionCurveRadius, FSelectionCurveRadius);
          end
          else
          begin
            Brush.Color := BackColor;
            FillRect(R);
          end;
        end;
      end;
      DoAfterItemErase(Canvas, Node, R);
    end;
  end;
end;

function TBaseVirtualTree.CompareNodePositions(Node1, Node2: PVirtualNode; ConsiderChildrenAbove: Boolean = False): Integer;

var
  Run1,
  Run2: PVirtualNode;
  Level1,
  Level2: Cardinal;

begin
  Assert(Assigned(Node1) and Assigned(Node2), 'Nodes must never be nil.');

  if Node1 = Node2 then
    Result := 0
  else
  begin
    if HasAsParent(Node1, Node2) then
      Result := IfThen(ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions), -1, 1)
    else
      if HasAsParent(Node2, Node1) then
        Result := IfThen(ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions), 1, -1)
      else
      begin
        
        Level1 := GetNodeLevel(Node1);
        Level2 := GetNodeLevel(Node2);
        Run1 := Node1;
        while Level1 > Level2 do
        begin
          Run1 := Run1.Parent;
          Dec(Level1);
        end;
        Run2 := Node2;
        while Level2 > Level1 do
        begin
          Run2 := Run2.Parent;
          Dec(Level2);
        end;
        
        while Run1.Parent <> Run2.Parent do
        begin
          Run1 := Run1.Parent;
          Run2 := Run2.Parent;
        end;
        Result := Integer(Run1.Index) - Integer(Run2.Index);
      end;
  end;
end;

procedure TBaseVirtualTree.DrawLineImage(const PaintInfo: TVTPaintInfo; X, Y, H, VAlign: Integer; Style: TVTLineType;
  Reverse: Boolean);

var
  HalfWidth,
  TargetX: Integer;

begin
  HalfWidth := Round(FIndent / 2);
  if Reverse then
    TargetX := 0
  else
    TargetX := FIndent;

  with PaintInfo.Canvas do
  begin
    case Style of
      ltBottomRight:
        begin
          DrawDottedVLine(PaintInfo, Y + VAlign, Y + H, X + HalfWidth);
          DrawDottedHLine(PaintInfo, X + HalfWidth, X + TargetX, Y + VAlign);
        end;
      ltTopDown:
        DrawDottedVLine(PaintInfo, Y, Y + H, X + HalfWidth);
      ltTopDownRight:
        begin
          DrawDottedVLine(PaintInfo, Y, Y + H, X + HalfWidth);
          DrawDottedHLine(PaintInfo, X + HalfWidth, X + TargetX, Y + VAlign);
        end;
      ltRight:
        DrawDottedHLine(PaintInfo, X + HalfWidth, X + TargetX, Y + VAlign);
      ltTopRight:
        begin
          DrawDottedVLine(PaintInfo, Y, Y + VAlign, X + HalfWidth);
          DrawDottedHLine(PaintInfo, X + HalfWidth, X + TargetX, Y + VAlign);
        end;
      ltLeft: 
        if Reverse then
          DrawDottedVLine(PaintInfo, Y, Y + H, X + Integer(FIndent))
        else
          DrawDottedVLine(PaintInfo, Y, Y + H, X);
      ltLeftBottom:
        if Reverse then
        begin
          DrawDottedVLine(PaintInfo, Y, Y + H, X + Integer(FIndent));
          DrawDottedHLine(PaintInfo, X, X + Integer(FIndent), Y + H);
        end
        else
        begin
          DrawDottedVLine(PaintInfo, Y, Y + H, X);
          DrawDottedHLine(PaintInfo, X, X + Integer(FIndent), Y + H);
        end;
    end;
  end;
end;

function TBaseVirtualTree.FindInPositionCache(Node: PVirtualNode; var CurrentPos: Cardinal): PVirtualNode;

var
  L, H, I: Integer;

begin
  L := 0;
  H := High(FPositionCache);
  while L <= H do
  begin
    I := (L + H) shr 1;
    if CompareNodePositions(FPositionCache[I].Node, Node) <= 0 then
      L := I + 1
    else
      H := I - 1;
  end;
  if L = 0 then 
  begin
    Result := nil;
    CurrentPos := 0;
  end
  else
  begin
    Result := FPositionCache[L - 1].Node;
    CurrentPos := FPositionCache[L - 1].AbsoluteTop;
  end;
end;

function TBaseVirtualTree.FindInPositionCache(Position: Cardinal; var CurrentPos: Cardinal): PVirtualNode;

var
  L, H, I: Integer;

begin
  L := 0;
  H := High(FPositionCache);
  while L <= H do
  begin
    I := (L + H) shr 1;
    if FPositionCache[I].AbsoluteTop <= Position then
      L := I + 1
    else
      H := I - 1;
  end;
  if L = 0 then 
  begin
    Result := nil;
    CurrentPos := 0;
  end
  else
  begin
    Result := FPositionCache[L - 1].Node;
    CurrentPos := FPositionCache[L - 1].AbsoluteTop;
  end;
end;

procedure TBaseVirtualTree.FixupTotalCount(Node: PVirtualNode);

var
  Child: PVirtualNode;

begin
  
  Child := Node.FirstChild;
  while Assigned(Child) do
  begin
    FixupTotalCount(Child);
    Inc(Node.TotalCount, Child.TotalCount);
    Child := Child.NextSibling;
  end;
end;

procedure TBaseVirtualTree.FixupTotalHeight(Node: PVirtualNode);

var
  Child: PVirtualNode;

begin
  
  Child := Node.FirstChild;

  if vsExpanded in Node.States then
  begin
    while Assigned(Child) do
    begin
      FixupTotalHeight(Child);
      if vsVisible in Child.States then
        Inc(Node.TotalHeight, Child.TotalHeight);
      Child := Child.NextSibling;
    end;
  end
  else
  begin
    
    while Assigned(Child) do
    begin
      FixupTotalHeight(Child);
      Child := Child.NextSibling;
    end;
  end;
end;

function TBaseVirtualTree.GetBottomNode: PVirtualNode;

begin
  Result := GetNodeAt(0, ClientHeight - 1);
end;

function TBaseVirtualTree.GetCheckedCount: Integer;

var
  Node: PVirtualNode;

begin
  Result := 0;
  Node := GetFirstChecked;
  while Assigned(Node) do begin
     Inc(Result);
     Node := GetNextChecked(Node);
  end;
end;

function TBaseVirtualTree.GetCheckState(Node: PVirtualNode): TCheckState;

begin
  Result := Node.CheckState;
end;

function TBaseVirtualTree.GetCheckType(Node: PVirtualNode): TCheckType;

begin
  Result := Node.CheckType;
end;

function TBaseVirtualTree.GetChildCount(Node: PVirtualNode): Cardinal;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := FRoot.ChildCount
  else
    Result := Node.ChildCount;
end;

function TBaseVirtualTree.GetChildrenInitialized(Node: PVirtualNode): Boolean;

begin
  Result := not (vsHasChildren in Node.States) or (Node.ChildCount > 0);
end;

function TBaseVirtualTree.GetCutCopyCount: Integer;

var
  Node: PVirtualNode;

begin
  Result := 0;
  Node := GetFirstCutCopy;
  while Assigned(Node) do begin
     Inc(Result);
     Node := GetNextCutCopy(Node);
  end;
end;

function TBaseVirtualTree.GetDisabled(Node: PVirtualNode): Boolean;

begin
  Result := Assigned(Node) and (vsDisabled in Node.States);
end;

function TBaseVirtualTree.GetDragManager: IVTDragManager;

begin
  if FDragManager = nil then
  begin
    FDragManager := DoCreateDragManager;
    if FDragManager = nil then
      FDragManager := TVTDragManager.Create(Self);
  end;

  Result := FDragManager;
end;

function TBaseVirtualTree.GetExpanded(Node: PVirtualNode): Boolean;

begin
  if Assigned(Node) then
    Result := vsExpanded in Node.States
  else
    Result := False;
end;

function TBaseVirtualTree.GetFiltered(Node: PVirtualNode): Boolean;

begin
  Result := vsFiltered in Node.States;
end;

function TBaseVirtualTree.GetFullyVisible(Node: PVirtualNode): Boolean;

begin
  Assert(Assigned(Node), 'Invalid parameter.');
  Result := vsVisible in Node.States;
  if Result and (Node <> FRoot) then
    Result := VisiblePath[Node];
end;

function TBaseVirtualTree.GetHasChildren(Node: PVirtualNode): Boolean;

begin
  if Assigned(Node) then
    Result := vsHasChildren in Node.States
  else
    Result := vsHasChildren in FRoot.States;
end;

function TBaseVirtualTree.GetMultiline(Node: PVirtualNode): Boolean;

begin
  Result := Assigned(Node) and (Node <> FRoot) and (vsMultiline in Node.States);
end;

function TBaseVirtualTree.GetNodeHeight(Node: PVirtualNode): Cardinal;

begin
  if Assigned(Node) and (Node <> FRoot) then
  begin
    if (toVariableNodeHeight in FOptions.FMiscOptions) and not (vsDeleting in Node.States) then
    begin
      if not (vsInitialized in Node.States) then
        InitNode(Node);
      
      MeasureItemHeight(Self.Canvas, Node);
    end;
    Result := Node.NodeHeight
  end
  else
    Result := 0;
end;

function TBaseVirtualTree.GetNodeParent(Node: PVirtualNode): PVirtualNode;

begin
  if Assigned(Node) and (Node.Parent <> FRoot) then
    Result := Node.Parent
  else
    Result := nil;
end;

function TBaseVirtualTree.GetOffsetXY: TPoint;

begin
  Result := Point(FOffsetX, FOffsetY);
end;

function TBaseVirtualTree.GetRangeX: Cardinal;
begin
  Result := Max(0, FRangeX);
end;

function TBaseVirtualTree.GetRootNodeCount: Cardinal;

begin
  Result := FRoot.ChildCount;
end;

function TBaseVirtualTree.GetSelected(Node: PVirtualNode): Boolean;

begin
  Result := Assigned(Node) and (vsSelected in Node.States);
end;

function TBaseVirtualTree.GetTopNode: PVirtualNode;

var
  Dummy: Integer;

begin
  Result := GetNodeAt(0, 0, True, Dummy);
end;

function TBaseVirtualTree.GetTotalCount: Cardinal;

begin
  Inc(FUpdateCount);
  try
    ValidateNode(FRoot, True);
  finally
    Dec(FUpdateCount);
  end;
  
  Result := FRoot.TotalCount - 1;
end;

function TBaseVirtualTree.GetVerticalAlignment(Node: PVirtualNode): Byte;

begin
  Result := Node.Align;
end;

function TBaseVirtualTree.GetVisible(Node: PVirtualNode): Boolean;

begin
  if Node = nil then
    Node := FRoot;

  if not (vsInitialized in Node.States) then
    InitNode(Node);

  Result := vsVisible in Node.States;
end;

function TBaseVirtualTree.GetVisiblePath(Node: PVirtualNode): Boolean;

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Invalid parameters.');
  
  repeat
    Node := Node.Parent;
  until (Node = FRoot) or not (vsExpanded in Node.States) or not (vsVisible in Node.States);

  Result := Node = FRoot;
end;

procedure TBaseVirtualTree.HandleClickSelection(LastFocused, NewNode: PVirtualNode; Shift: TShiftState;
  DragPending: Boolean);

begin
  
  if ssCtrl in Shift then
  begin
    if ssShift in Shift then
    begin
      SelectNodes(FRangeAnchor, NewNode, True);
    end
    else
    begin
      if not (toSiblingSelectConstraint in FOptions.SelectionOptions) then
        FRangeAnchor := NewNode;
      
      if DragPending then
        DoStateChange([tsToggleFocusedSelection])
      else
        if vsSelected in NewNode.States then
          RemoveFromSelection(NewNode)
        else
          AddToSelection(NewNode);
    end;
    Invalidate();
  end
  else
    
    if ssShift in Shift then
    begin
      if FRangeAnchor = nil then
        FRangeAnchor := FRoot.FirstChild;
      
      if Assigned(FRangeAnchor) then
      begin
        SelectNodes(FRangeAnchor, NewNode, False);
        Invalidate;
      end;
    end
    else
    begin
      
      if not (vsSelected in NewNode.States) then
      begin
        AddToSelection(NewNode);
        InvalidateNode(NewNode);
      end;
      
      FRangeAnchor := NewNode;
    end;
end;

function TBaseVirtualTree.HandleDrawSelection(X, Y: Integer): Boolean;

var
  OldRect,
  NewRect: TRect;
  MainColumn: TColumnIndex;
  MaxValue: Integer;
  
  NodeLeft,
  NodeRight: Integer;
  
  CurrentBidiMode: TBidiMode;
  CurrentAlignment: TAlignment;

begin
  Result := False;
  
  if (FRoot.TotalCount > 1) and (tsDrawSelecting in FStates) then
  begin
    
    OldRect := OrderRect(FLastSelRect);
    NewRect := OrderRect(FNewSelRect);
    ClearTempCache;

    MainColumn := FHeader.MainColumn;
    
    if MainColumn <= NoColumn then
    begin
      CurrentBidiMode := BidiMode;
      CurrentAlignment := Alignment;
    end
    else
    begin
      CurrentBidiMode := FHeader.FColumns[MainColumn].BidiMode;
      CurrentAlignment := FHeader.FColumns[MainColumn].Alignment;
    end;
    
    if FHeader.UseColumns then
    begin
      
      NodeLeft := FHeader.FColumns[MainColumn].Left - FEffectiveOffsetX;
      NodeRight := NodeLeft + FHeader.FColumns[MainColumn].Width;
    end
    else
    begin
      NodeLeft := 0;
      NodeRight := ClientWidth;
    end;
    if CurrentBidiMode = bdLeftToRight then
      Result := CollectSelectedNodesLTR(MainColumn, NodeLeft, NodeRight, CurrentAlignment, OldRect, NewRect)
    else
      Result := CollectSelectedNodesRTL(MainColumn, NodeLeft, NodeRight, CurrentAlignment, OldRect, NewRect);
  end;

  if Result then
  begin
    
    MaxValue := PackArray(FSelection, FSelectionCount);
    if MaxValue > -1 then
    begin
      FSelectionCount := MaxValue;
      SetLength(FSelection, FSelectionCount);
    end;
    if FTempNodeCount > 0 then
    begin
      AddToSelection(FTempNodeCache, FTempNodeCount);
      ClearTempCache;
    end;

    Change(nil);
  end;
end;

function TBaseVirtualTree.HasVisibleNextSibling(Node: PVirtualNode): Boolean;

begin
  
  Result := Assigned(Node.NextSibling);

  if Result then
  begin
    repeat
      Node := Node.NextSibling;
      Result := IsEffectivelyVisible[Node];
    until Result or (Node.NextSibling = nil);
  end;
end;

function TBaseVirtualTree.HasVisiblePreviousSibling(Node: PVirtualNode): Boolean;

begin
  
  Result := Assigned(Node.PrevSibling);

  if Result then
  begin
    repeat
      Node := Node.PrevSibling;
      Result := IsEffectivelyVisible[Node];
    until Result or (Node.PrevSibling = nil);
  end;
end;

procedure TBaseVirtualTree.ImageListChange(Sender: TObject);

begin
  if not (csDestroying in ComponentState) then
    Invalidate;
end;

procedure TBaseVirtualTree.InitializeFirstColumnValues(var PaintInfo: TVTPaintInfo);

begin
  PaintInfo.Column := FHeader.FColumns.GetFirstVisibleColumn;
  with FHeader.FColumns, PaintInfo do
  begin
    if Column > NoColumn then
    begin
      CellRect.Right := CellRect.Left + Items[Column].Width;
      Position := Items[Column].Position;
    end
    else
      Position := 0;
  end;
end;

procedure TBaseVirtualTree.InitRootNode(OldSize: Cardinal = 0);

var
  NewSize: Cardinal;

begin
  NewSize := TreeNodeSize + FTotalInternalDataSize;
  if FRoot = nil then
    FRoot := AllocMem(NewSize)
  else
  begin
    ReallocMem(FRoot, NewSize);
    ZeroMemory(PByte(FRoot) + OldSize, NewSize - OldSize);
  end;

  with FRoot^ do
  begin
    
    PrevSibling := FRoot;
    NextSibling := FRoot;
    Parent := Pointer(Self);
    States := [vsInitialized, vsExpanded, vsHasChildren, vsVisible];
    TotalHeight := FDefaultNodeHeight;
    TotalCount := 1;
    TotalHeight := FDefaultNodeHeight;
    NodeHeight := FDefaultNodeHeight;
    Align := 50;
  end;
end;

procedure TBaseVirtualTree.InterruptValidation;

var
  WasValidating: Boolean;

begin
  DoStateChange([tsStopValidation], [tsUseCache]);
  
  if Assigned(WorkerThread) then
  begin
    WasValidating := (tsValidating in FStates);
    WorkerThread.RemoveTree(Self);
    if WasValidating then
      DoStateChange([tsValidationNeeded]);
  end;
end;

function TBaseVirtualTree.IsFirstVisibleChild(Parent, Node: PVirtualNode): Boolean;

var
  Run: PVirtualNode;

begin
  
  Run := Parent.FirstChild;
  while Assigned(Run) and not IsEffectivelyVisible[Run] do
    Run := Run.NextSibling;

  Result := Assigned(Run) and (Run = Node);
end;

function TBaseVirtualTree.IsLastVisibleChild(Parent, Node: PVirtualNode): Boolean;

var
  Run: PVirtualNode;

begin
  
  Run := Parent.LastChild;
  while Assigned(Run) and not IsEffectivelyVisible[Run] do
    Run := Run.PrevSibling;

  Result := Assigned(Run) and (Run = Node);
end;

function TBaseVirtualTree.MakeNewNode: PVirtualNode;

var
  Size: Cardinal;

begin
  Size := TreeNodeSize;
  if not (csDesigning in ComponentState) then
  begin
    
    if FNodeDataSize = -1 then
      ValidateNodeDataSize(FNodeDataSize);
    
    Inc(Size, FNodeDataSize);
  end;

  Result := AllocMem(Size + FTotalInternalDataSize);
  
  with Result^ do
  begin
    TotalCount := 1;
    TotalHeight := FDefaultNodeHeight;
    NodeHeight := FDefaultNodeHeight;
    States := [vsVisible];
    Align := 50;
  end;
end;

function TBaseVirtualTree.PackArray(const TheArray: TNodeArray; Count: Integer): Integer; assembler;

{$ifdef CPUX64}
var
  Source, Dest: ^PVirtualNode;
  ConstOne: NativeInt;
begin
  Source := Pointer(TheArray);
  ConstOne := 1;
  Result := 0;
  
  while (Count <> 0) and  (NativeInt(Source^) and ConstOne = 0) do
  begin
    Inc(Result);
    Inc(Source);
    Dec(Count);
  end;

  if Count <> 0 then
  begin
    Dest := Source;
    repeat
      
      if  NativeInt(Source^) and ConstOne = 0 then
      begin
        Dest^ := Source^;
        Inc(Result);
        Inc(Dest);
      end;
      Inc(Source); 
      Dec(Count);
    until Count = 0;
  end;
end;
{$else}
asm
        PUSH    EBX
        PUSH    EDI
        PUSH    ESI
        MOV     ESI, EDX
        MOV     EDX, -1
        JCXZ    @@Finish               
        INC     EDX                    
        MOV     EDI, ESI               
        MOV     EBX, 1                 
@@PreScan:
        TEST    [ESI], EBX             
                                       
        JNZ     @@DoMainLoop
        INC     EDX
        ADD     ESI, 4
        DEC     ECX
        JNZ     @@PreScan
        JMP     @@Finish

@@DoMainLoop:
        MOV     EDI, ESI
@@MainLoop:
        TEST    [ESI], EBX             
        JNE     @@Skip                 
        MOVSD                          
        INC     EDX                    
        DEC     ECX
        JNZ     @@MainLoop             
        JMP     @@Finish

@@Skip:
        ADD     ESI, 4                 
        DEC     ECX
        JNZ     @@MainLoop             
@@Finish:
        MOV     EAX, EDX               
        POP     ESI
        POP     EDI
        POP     EBX
end;
{$endif CPUX64}

procedure TBaseVirtualTree.PrepareBitmaps(NeedButtons, NeedLines: Boolean);

const
  LineBitsDotted: array [0..8] of Word = ($55, $AA, $55, $AA, $55, $AA, $55, $AA, $55);
  LineBitsSolid: array [0..7] of Word = (0, 0, 0, 0, 0, 0, 0, 0);

var
  PatternBitmap: HBITMAP;
  Bits: Pointer;
  Size: TSize;
  Theme: HTHEME;
  R: TRect;

  procedure FillBitmap (ABitmap: TBitmap);
  begin
    with ABitmap, Canvas do
    begin
      Width := Size.cx;
      Height := Size.cy;

      if IsWinVistaOrAbove and (tsUseThemes in FStates) and (toUseExplorerTheme in FOptions.FPaintOptions) or VclStyleEnabled then
      begin
        if (FHeader.MainColumn > NoColumn) and not (coParentColor in FHeader.FColumns[FHeader.MainColumn].Options) then
          Brush.Color := FHeader.FColumns[FHeader.MainColumn].Color
        else
          Brush.Color :=  FColors.BackGroundColor;
      end
      else
        Brush.Color := clFuchsia;

      Transparent := True;
      TransparentColor := Brush.Color;

      FillRect(Rect(0, 0, Width, Height));
    end;
  end;

begin
  Size.cx := 9;
  Size.cy := 9;

  if tsUseThemes in FStates then
  begin
    R := Rect(0, 0, 100, 100);
    Theme := OpenThemeData(Handle, 'TREEVIEW');
    GetThemePartSize(Theme, FPlusBM.Canvas.Handle, TVP_GLYPH, GLPS_OPENED, @R, TS_TRUE, Size);
  end
  else
    Theme := 0;

  if NeedButtons then
  begin
     with FMinusBM, Canvas do
     begin
      
      FillBitmap(FMinusBM);
      FillBitmap(FHotMinusBM);
      
      if (not VclStyleEnabled) or (Theme = 0) then
      begin
        if not(tsUseExplorerTheme in FStates) then
        begin
          if FButtonStyle = bsTriangle then
          begin
            Brush.Color := clBlack;
            Pen.Color := clBlack;
            Polygon([Point(0, 2), Point(8, 2), Point(4, 6)]);
          end
          else
          begin
            
            if FButtonFillMode in [fmTreeColor, fmWindowColor, fmTransparent] then
            begin
              case FButtonFillMode of
                fmTreeColor:
                  Brush.Color := FColors.BackGroundColor;
                fmWindowColor:
                  Brush.Color := clWindow;
              end;
              Pen.Color := FColors.TreeLineColor;
              Rectangle(0, 0, Width, Height);
              Pen.Color := FColors.NodeFontColor;
              MoveTo(2, Width div 2);
              LineTo(Width - 2, Width div 2);
            end
            else
              FMinusBM.Handle := LoadBitmap(HInstance, 'VT_XPBUTTONMINUS');
            FHotMinusBM.Canvas.Draw(0, 0, FMinusBM);
          end;
        end;
      end;
    end;

    with FPlusBM, Canvas do
    begin
      FillBitmap(FPlusBM);
      FillBitmap(FHotPlusBM);
      if (not VclStyleEnabled) or (Theme = 0) then
      begin
        if not(tsUseExplorerTheme in FStates) then
        begin
          if FButtonStyle = bsTriangle then
          begin
            Brush.Color := clBlack;
            Pen.Color := clBlack;
            Polygon([Point(2, 0), Point(6, 4), Point(2, 8)]);
          end
          else
          begin
            
            if FButtonFillMode in [fmTreeColor, fmWindowColor, fmTransparent] then
            begin
              case FButtonFillMode of
                fmTreeColor:
                  Brush.Color := FColors.BackGroundColor;
                fmWindowColor:
                  Brush.Color := clWindow;
              end;

              Pen.Color := FColors.TreeLineColor;
              Rectangle(0, 0, Width, Height);
              Pen.Color := FColors.NodeFontColor;
              MoveTo(2, Width div 2);
              LineTo(Width - 2, Width div 2);
              MoveTo(Width div 2, 2);
              LineTo(Width div 2, Width - 2);
            end
            else
              FPlusBM.Handle := LoadBitmap(HInstance, 'VT_XPBUTTONPLUS');
            FHotPlusBM.Canvas.Draw(0, 0, FPlusBM);
          end;
        end;
      end;
    end;
    
    if (tsUseThemes in FStates) and (Theme <> 0) then
    begin
      R := Rect(0, 0, Size.cx, Size.cy);
      DrawThemeBackground(Theme, FPlusBM.Canvas.Handle, TVP_GLYPH, GLPS_CLOSED, R, nil);
      DrawThemeBackground(Theme, FMinusBM.Canvas.Handle, TVP_GLYPH, GLPS_OPENED, R, nil);
      if tsUseExplorerTheme in FStates then
      begin
        DrawThemeBackground(Theme, FHotPlusBM.Canvas.Handle, TVP_HOTGLYPH, GLPS_CLOSED, R, nil);
        DrawThemeBackground(Theme, FHotMinusBM.Canvas.Handle, TVP_HOTGLYPH, GLPS_OPENED, R, nil);
      end
      else
      begin
        FHotPlusBM.Canvas.Draw(0, 0, FPlusBM);
        FHotMinusBM.Canvas.Draw(0, 0, FMinusBM);
      end;
    end;
  end;

  if NeedLines then
  begin
    if FDottedBrush <> 0 then
      DeleteObject(FDottedBrush);

    case FLineStyle of
      lsDotted:
        Bits := @LineBitsDotted;
      lsSolid:
        Bits := @LineBitsSolid;
    else 
      Bits := @LineBitsDotted;
      DoGetLineStyle(Bits);
    end;
    PatternBitmap := CreateBitmap(8, 8, 1, 1, Bits);
    FDottedBrush := CreatePatternBrush(PatternBitmap);
    DeleteObject(PatternBitmap);
  end;

  if tsUseThemes in FStates then
    CloseThemeData(Theme);
end;

type
  TOldVTOption = (voAcceptOLEDrop, voAnimatedToggle, voAutoDropExpand, voAutoExpand, voAutoScroll,
    voAutoSort, voAutoSpanColumns, voAutoTristateTracking, voCheckSupport, voDisableDrawSelection, voEditable,
    voExtendedFocus, voFullRowSelect, voGridExtensions, voHideFocusRect, voHideSelection, voHotTrack, voInitOnSave,
    voLevelSelectConstraint, voMiddleClickSelect, voMultiSelect, voRightClickSelect, voPopupMode, voShowBackground,
    voShowButtons, voShowDropmark, voShowHorzGridLines, voShowRoot, voShowTreeLines, voShowVertGridLines,
    voSiblingSelectConstraint, voToggleOnDblClick);

const
  OptionMap: array[TOldVTOption] of Integer = (
    Ord(toAcceptOLEDrop), Ord(toAnimatedToggle), Ord(toAutoDropExpand), Ord(toAutoExpand), Ord(toAutoScroll),
    Ord(toAutoSort), Ord(toAutoSpanColumns), Ord(toAutoTristateTracking), Ord(toCheckSupport), Ord(toDisableDrawSelection),
    Ord(toEditable), Ord(toExtendedFocus), Ord(toFullRowSelect), Ord(toGridExtensions), Ord(toHideFocusRect),
    Ord(toHideSelection), Ord(toHotTrack), Ord(toInitOnSave), Ord(toLevelSelectConstraint), Ord(toMiddleClickSelect),
    Ord(toMultiSelect), Ord(toRightClickSelect), Ord(toPopupMode), Ord(toShowBackground),
    Ord(toShowButtons), Ord(toShowDropmark), Ord(toShowHorzGridLines), Ord(toShowRoot), Ord(toShowTreeLines),
    Ord(toShowVertGridLines), Ord(toSiblingSelectConstraint), Ord(toToggleOnDblClick)
  );

procedure TBaseVirtualTree.ReadOldOptions(Reader: TReader);

var
  OldOption: TOldVTOption;
  EnumName: string;

begin
  
  UpdateDesigner;
  
  if Reader.ReadValue = vaSet then
  begin
    
    FOptions.AnimationOptions := [];
    FOptions.AutoOptions := [];
    FOptions.MiscOptions := [];
    FOptions.PaintOptions := [];
    FOptions.SelectionOptions := [];

    while True do
    begin
      
      EnumName := Reader.ReadStr;
      if EnumName = '' then
        Break;
      OldOption := TOldVTOption(GetEnumValue(TypeInfo(TOldVTOption), EnumName));
      case OldOption of
        voAcceptOLEDrop, voCheckSupport, voEditable, voGridExtensions, voInitOnSave, voToggleOnDblClick:
          FOptions.MiscOptions := FOptions.FMiscOptions + [TVTMiscOption(OptionMap[OldOption])];
        voAnimatedToggle:
          FOptions.AnimationOptions := FOptions.FAnimationOptions + [TVTAnimationOption(OptionMap[OldOption])];
        voAutoDropExpand, voAutoExpand, voAutoScroll, voAutoSort, voAutoSpanColumns, voAutoTristateTracking:
          FOptions.AutoOptions := FOptions.FAutoOptions + [TVTAutoOption(OptionMap[OldOption])];
        voDisableDrawSelection, voExtendedFocus, voFullRowSelect, voLevelSelectConstraint,
        voMiddleClickSelect, voMultiSelect, voRightClickSelect, voSiblingSelectConstraint:
          FOptions.SelectionOptions := FOptions.FSelectionOptions + [TVTSelectionOption(OptionMap[OldOption])];
        voHideFocusRect, voHideSelection, voHotTrack, voPopupMode, voShowBackground, voShowButtons,
        voShowDropmark, voShowHorzGridLines, voShowRoot, voShowTreeLines, voShowVertGridLines:
          FOptions.PaintOptions := FOptions.FPaintOptions + [TVTPaintOption(OptionMap[OldOption])];
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.SetAlignment(const Value: TAlignment);

begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    if not (csLoading in ComponentState) then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetAnimationDuration(const Value: Cardinal);

begin
  FAnimationDuration := Value;
  if FAnimationDuration = 0 then
    Exclude(FOptions.FAnimationOptions, toAnimatedToggle)
  else
    Include(FOptions.FAnimationOptions, toAnimatedToggle);
end;

procedure TBaseVirtualTree.SetBackground(const Value: TPicture);

begin
  FBackground.Assign(Value);
  Invalidate;
end;

procedure TBaseVirtualTree.SetBackgroundOffset(const Index, Value: Integer);

begin
  case Index of
    0:
      if FBackgroundOffsetX <> Value then
      begin
        FBackgroundOffsetX := Value;
        Invalidate;
      end;
    1:
      if FBackgroundOffsetY <> Value then
      begin
        FBackgroundOffsetY := Value;
        Invalidate;
      end;
  end;
end;

procedure TBaseVirtualTree.SetBorderStyle(Value: TBorderStyle);

begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    RecreateWnd;
  end;
end;

procedure TBaseVirtualTree.SetBottomNode(Node: PVirtualNode);

var
  Run: PVirtualNode;
  R: TRect;

begin
  if Assigned(Node) then
  begin
    
    Run := Node.Parent;
    while Run <> FRoot do
    begin
      if not (vsExpanded in Run.States) then
        ToggleNode(Run);
      Run := Run.Parent;
    end;
    R := GetDisplayRect(Node, FHeader.MainColumn, True);
    DoSetOffsetXY(Point(FOffsetX, FOffsetY + ClientHeight - R.Top - Integer(NodeHeight[Node])),
      [suoRepaintScrollbars, suoUpdateNCArea]);
  end;
end;

procedure TBaseVirtualTree.SetBottomSpace(const Value: Cardinal);

begin
  if FBottomSpace <> Value then
  begin
    FBottomSpace := Value;
    UpdateVerticalScrollbar(True);
  end;
end;

procedure TBaseVirtualTree.SetButtonFillMode(const Value: TVTButtonFillMode);

begin
  if FButtonFillMode <> Value then
  begin
    FButtonFillMode := Value;
    if not (csLoading in ComponentState) then
    begin
      PrepareBitmaps(True, False);
      if HandleAllocated then
        Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.SetButtonStyle(const Value: TVTButtonStyle);

begin
  if FButtonStyle <> Value then
  begin
    FButtonStyle := Value;
    if not (csLoading in ComponentState) then
    begin
      PrepareBitmaps(True, False);
      if HandleAllocated then
        Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.SetCheckImageKind(Value: TCheckImageKind);

begin
  if FCheckImageKind <> Value then
  begin
    FCheckImageKind := Value;
    FCheckImages := GetCheckImageListFor(Value);
    if not Assigned(FCheckImages) then
      FCheckImages := FCustomCheckImages;
    if HandleAllocated and (FUpdateCount = 0) and not (csLoading in ComponentState) then
      InvalidateRect(Handle, nil, False);
  end;
end;

procedure TBaseVirtualTree.SetCheckState(Node: PVirtualNode; Value: TCheckState);

begin
  if (Node.CheckState <> Value) and not (vsDisabled in Node.States) and DoChecking(Node, Value) then
    DoCheckClick(Node, Value);
end;

procedure TBaseVirtualTree.SetCheckType(Node: PVirtualNode; Value: TCheckType);

begin
  if (Node.CheckType <> Value) and not (toReadOnly in FOptions.FMiscOptions) then
  begin
    Node.CheckType := Value;
    if (Value <> ctTriStateCheckBox) and (Node.CheckState in [csMixedNormal, csMixedPressed]) then
      Node.CheckState := csUncheckedNormal;
    
    if (toAutoTriStateTracking in FOptions.FAutoOptions) and (Value in [ctCheckBox, ctTriStateCheckBox]) and
      (Node.Parent <> FRoot) then
    begin
      if not (vsInitialized in Node.Parent.States) then
        InitNode(Node.Parent);
      if (Node.Parent.CheckType = ctTriStateCheckBox) and
        (Node.Parent.CheckState in [csUncheckedNormal, csCheckedNormal]) then
        CheckState[Node] := Node.Parent.CheckState;
    end;
    InvalidateNode(Node);
  end;
end;

procedure TBaseVirtualTree.SetChildCount(Node: PVirtualNode; NewChildCount: Cardinal);

var
  Remaining: Cardinal;
  Index: Cardinal;
  Child: PVirtualNode;
  Count: Integer;
  NewHeight: Integer;

begin
  if not (toReadOnly in FOptions.FMiscOptions) then
  begin
    if Node = nil then
      Node := FRoot;

    if NewChildCount = 0 then
      DeleteChildren(Node)
    else
    begin
      
      if NewChildCount <> Node.ChildCount then
      begin
        InterruptValidation;
        NewHeight := 0;

        if NewChildCount > Node.ChildCount then
        begin
          Remaining := NewChildCount - Node.ChildCount;
          Count := Remaining;
          
          if Assigned(Node.LastChild) then
            Index := Node.LastChild.Index + 1
          else
          begin
            Index := 0;
            Include(Node.States, vsHasChildren);
          end;
          Node.States := Node.States - [vsAllChildrenHidden, vsHeightMeasured];
          
          while Remaining > 0 do
          begin
            Child := MakeNewNode;
            Child.Index := Index;
            Child.PrevSibling := Node.LastChild;
            if Assigned(Node.LastChild) then
              Node.LastChild.NextSibling := Child;
            Child.Parent := Node;
            Node.LastChild := Child;
            if Node.FirstChild = nil then
              Node.FirstChild := Child;
            Dec(Remaining);
            Inc(Index);
            
            Inc(NewHeight, Child.NodeHeight);
          end;

          if vsExpanded in Node.States then
          begin
            AdjustTotalHeight(Node, NewHeight, True);
            if FullyVisible[Node] then
              Inc(Integer(FVisibleCount), Count);
          end;

          AdjustTotalCount(Node, Count, True);
          Node.ChildCount := NewChildCount;
          if (FUpdateCount = 0) and (toAutoSort in FOptions.FAutoOptions) and (FHeader.FSortColumn > InvalidColumn) then
            Sort(Node, FHeader.FSortColumn, FHeader.FSortDirection, True);

          InvalidateCache;
        end
        else
        begin
          
          Remaining := Node.ChildCount - NewChildCount;
          while Remaining > 0 do
          begin
            DeleteNode(Node.LastChild);
            Dec(Remaining);
          end;
        end;

        if FUpdateCount = 0 then
        begin
          ValidateCache;
          UpdateScrollBars(True);
          Invalidate;
        end;

        if Node = FRoot then
          StructureChange(nil, crChildAdded)
        else
          StructureChange(Node, crChildAdded);
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.SetClipboardFormats(const Value: TClipboardFormats);

var
  I: Integer;

begin
  
  FClipboardFormats.Clear;
  for I := 0 to Value.Count - 1 do
    FClipboardFormats.Add(Value[I]);
end;

procedure TBaseVirtualTree.SetColors(const Value: TVTColors);

begin
  FColors.Assign(Value);
end;

procedure TBaseVirtualTree.SetCustomCheckImages(const Value: TCustomImageList);

begin
  if FCustomCheckImages <> Value then
  begin
    if Assigned(FCustomCheckImages) then
    begin
      FCustomCheckImages.UnRegisterChanges(FCustomCheckChangeLink);
      FCustomCheckImages.RemoveFreeNotification(Self);
      
      if FCheckImages = FCustomCheckImages then
        FCheckImages := nil;
    end;
    FCustomCheckImages := Value;
    if Assigned(FCustomCheckImages) then
    begin
      FCustomCheckImages.RegisterChanges(FCustomCheckChangeLink);
      FCustomCheckImages.FreeNotification(Self);
    end;
    
    if FCheckImageKind = ckCustom then
      FCheckImages := Value;
    if not (csLoading in ComponentState) then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetDefaultNodeHeight(Value: Cardinal);

begin
  if Value = 0 then
    Value := 18;
  if FDefaultNodeHeight <> Value then
  begin
    Inc(Integer(FRoot.TotalHeight), Integer(Value) - Integer(FDefaultNodeHeight));
    Inc(SmallInt(FRoot.NodeHeight), Integer(Value) - Integer(FDefaultNodeHeight));
    FDefaultNodeHeight := Value;
    InvalidateCache;
    if (FUpdateCount = 0) and HandleAllocated and not (csLoading in ComponentState) then
    begin
      ValidateCache;
      UpdateScrollBars(True);
      ScrollIntoView(FFocusedNode, toCenterScrollIntoView in FOptions.SelectionOptions, True);
      Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.SetDisabled(Node: PVirtualNode; Value: Boolean);

begin
  if Assigned(Node) and (Value xor (vsDisabled in Node.States)) then
  begin
    if Value then
      Include(Node.States, vsDisabled)
    else
      Exclude(Node.States, vsDisabled);

    if FUpdateCount = 0 then
      InvalidateNode(Node);
  end;
end;

procedure TBaseVirtualTree.SetDoubleBuffered(const Value: Boolean);
begin
  
end;

function TBaseVirtualTree.GetDoubleBuffered: Boolean;
begin
  Result := True; 
end;

procedure TBaseVirtualTree.SetEmptyListMessage(const Value: UnicodeString);

begin
  if Value <> EmptyListMessage then
  begin
    FEmptyListMessage := Value;
    Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetExpanded(Node: PVirtualNode; Value: Boolean);

begin
  if Assigned(Node) and (Node <> FRoot) and (Value xor (vsExpanded in Node.States)) then
    ToggleNode(Node);
end;

procedure TBaseVirtualTree.SetFocusedColumn(Value: TColumnIndex);

begin
  if (FFocusedColumn <> Value) and
     DoFocusChanging(FFocusedNode, FFocusedNode, FFocusedColumn, Value) then
  begin
    CancelEditNode;
    InvalidateColumn(FFocusedColumn);
    InvalidateColumn(Value);
    FFocusedColumn := Value;
    if Assigned(FFocusedNode) and not (toDisableAutoscrollOnFocus in FOptions.FAutoOptions) then
    begin
      if ScrollIntoView(FFocusedNode, toCenterScrollIntoView in FOptions.SelectionOptions, True) then
        InvalidateNode(FFocusedNode);
    end;

    if Assigned(FDropTargetNode) then
      InvalidateNode(FDropTargetNode);

    DoFocusChange(FFocusedNode, FFocusedColumn);
  end;
end;

procedure TBaseVirtualTree.SetFocusedNode(Value: PVirtualNode);

var
  WasDifferent: Boolean;

begin
  WasDifferent := Value <> FFocusedNode;
  DoFocusNode(Value, True);
  
  if WasDifferent and (FFocusedNode = Value) then
    DoFocusChange(FFocusedNode, FFocusedColumn);
end;

procedure TBaseVirtualTree.SetFullyVisible(Node: PVirtualNode; Value: Boolean);

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Invalid parameter');

  IsVisible[Node] := Value;
  if Value then
  begin
    repeat
      Node := Node.Parent;
      if Node = FRoot then
        Break;
      if not (vsExpanded in Node.States) then
        ToggleNode(Node);
      if not (vsVisible in Node.States) then
        IsVisible[Node] := True;
    until False;
  end;
end;

procedure TBaseVirtualTree.SetHasChildren(Node: PVirtualNode; Value: Boolean);

begin
  if Assigned(Node) and not (toReadOnly in FOptions.FMiscOptions) then
  begin
    if Value then
      Include(Node.States, vsHasChildren)
    else
    begin
      Exclude(Node.States, vsHasChildren);
      DeleteChildren(Node);
    end;
  end;
end;

procedure TBaseVirtualTree.SetHeader(const Value: TVTHeader);

begin
  FHeader.Assign(Value);
end;

procedure TBaseVirtualTree.SetFiltered(Node: PVirtualNode; Value: Boolean);

var
  NeedUpdate: Boolean;

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Invalid parameter.');
  
  if not (vsInitialized in Node.States) then
    InitNode(Node);

  if Value <> (vsFiltered in Node.States) then
  begin
    InterruptValidation;
    NeedUpdate := False;
    if Value then
    begin
      Include(Node.States, vsFiltered);
      if not (toShowFilteredNodes in FOptions.FPaintOptions) then
      begin
        AdjustTotalHeight(Node, -Integer(NodeHeight[Node]), True);
        if FullyVisible[Node] then
        begin
          Dec(FVisibleCount);
          NeedUpdate := True;
        end;
      end;

      if FUpdateCount = 0 then
        DetermineHiddenChildrenFlag(Node.Parent)
      else
        Include(FStates, tsUpdateHiddenChildrenNeeded);
    end
    else
    begin
      Exclude(Node.States, vsFiltered);
      if not (toShowFilteredNodes in FOptions.FPaintOptions) then
      begin
        AdjustTotalHeight(Node, Integer(NodeHeight[Node]), True);
        if FullyVisible[Node] then
        begin
          Inc(FVisibleCount);
          NeedUpdate := True;
        end;
      end;

      if vsVisible in Node.States then
        
        Exclude(Node.Parent.States, vsAllChildrenHidden);
    end;

    InvalidateCache;
    if NeedUpdate and (FUpdateCount = 0) then
    begin
      ValidateCache;
      UpdateScrollBars(True);
      Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.SetImages(const Value: TCustomImageList);

begin
  if FImages <> Value then
  begin
    if Assigned(FImages) then
    begin
      FImages.UnRegisterChanges(FImageChangeLink);
      FImages.RemoveFreeNotification(Self);
    end;
    FImages := Value;
    if Assigned(FImages) then
    begin
      FImages.RegisterChanges(FImageChangeLink);
      FImages.FreeNotification(Self);
    end;
    if not (csLoading in ComponentState) then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetIndent(Value: Cardinal);

begin
  if FIndent <> Value then
  begin
    FIndent := Value;
    if not (csLoading in ComponentState) and (FUpdateCount = 0) and HandleAllocated then
    begin
      UpdateScrollBars(True);
      Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.SetLineMode(const Value: TVTLineMode);

begin
  if FLineMode <> Value then
  begin
    FLineMode := Value;
    if HandleAllocated and not (csLoading in ComponentState) then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetLineStyle(const Value: TVTLineStyle);

begin
  if FLineStyle <> Value then
  begin
    FLineStyle := Value;
    if not (csLoading in ComponentState) then
    begin
      PrepareBitmaps(False, True);
      if HandleAllocated then
        Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.SetMargin(Value: Integer);

begin
  if FMargin <> Value then
  begin
    FMargin := Value;
    if HandleAllocated and not (csLoading in ComponentState) then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetMultiline(Node: PVirtualNode; const Value: Boolean);

begin
  if Assigned(Node) and (Node <> FRoot) then
    if Value <> (vsMultiline in Node.States) then
    begin
      if Value then
        Include(Node.States, vsMultiline)
      else
        Exclude(Node.States, vsMultiline);

      if FUpdateCount = 0 then
        InvalidateNode(Node);
    end;
end;

procedure TBaseVirtualTree.SetNodeAlignment(const Value: TVTNodeAlignment);

begin
  if FNodeAlignment <> Value then
  begin
    FNodeAlignment := Value;
    if HandleAllocated and not (csReading in ComponentState) then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetNodeDataSize(Value: Integer);

var
  LastRootCount: Cardinal;

begin
  if Value < -1 then
    Value := -1;
  if FNodeDataSize <> Value then
  begin
    FNodeDataSize := Value;
    if not (csLoading in ComponentState) and not (csDesigning in ComponentState) then
    begin
      LastRootCount := FRoot.ChildCount;
      Clear;
      SetRootNodeCount(LastRootCount);
    end;
  end;
end;

procedure TBaseVirtualTree.SetNodeHeight(Node: PVirtualNode; Value: Cardinal);

var
  Difference: Integer;

begin
  if Assigned(Node) and (Node <> FRoot) and (Node.NodeHeight <> Value) and not (toReadOnly in FOptions.FMiscOptions) then
  begin
    Difference := Integer(Value) - Integer(Node.NodeHeight);
    Node.NodeHeight := Value;
    
    if not IsEffectivelyFiltered[Node] then
    begin
      AdjustTotalHeight(Node, Difference, True);
      
      UpdateEditBounds;
      
      if not (tsValidating in FStates) and FullyVisible[Node] and not IsEffectivelyFiltered[Node] then
      begin
        InvalidateCache;
        if (FUpdateCount = 0) and ([tsPainting, tsSizing] * FStates = []) then
        begin
          ValidateCache;
          InvalidateToBottom(Node);
          UpdateScrollBars(True);
        end;
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.SetNodeParent(Node: PVirtualNode; const Value: PVirtualNode);

begin
  if Assigned(Node) and Assigned(Value) and (Node.Parent <> Value) then
    MoveTo(Node, Value, amAddChildLast, False);
end;

procedure TBaseVirtualTree.SetOffsetX(const Value: Integer);

begin
  DoSetOffsetXY(Point(Value, FOffsetY), DefaultScrollUpdateFlags);
end;

procedure TBaseVirtualTree.SetOffsetXY(const Value: TPoint);

begin
  DoSetOffsetXY(Value, DefaultScrollUpdateFlags);
end;

procedure TBaseVirtualTree.SetOffsetY(const Value: Integer);

begin
  DoSetOffsetXY(Point(FOffsetX, Value), DefaultScrollUpdateFlags);
end;

procedure TBaseVirtualTree.SetOptions(const Value: TCustomVirtualTreeOptions);

begin
  FOptions.Assign(Value);
end;

procedure TBaseVirtualTree.SetRootNodeCount(Value: Cardinal);

begin
  
  if csLoading in ComponentState then
  begin
    FRoot.ChildCount := Value;
    DoStateChange([tsNeedRootCountUpdate]);
  end
  else
    if FRoot.ChildCount <> Value then
    begin
      BeginUpdate;
      InterruptValidation;
      SetChildCount(FRoot, Value);
      EndUpdate;
    end;
end;

procedure TBaseVirtualTree.SetScrollBarOptions(Value: TScrollBarOptions);

begin
  FScrollBarOptions.Assign(Value);
end;

procedure TBaseVirtualTree.SetSearchOption(const Value: TVTIncrementalSearch);

begin
  if FIncrementalSearch <> Value then
  begin
    FIncrementalSearch := Value;
    if FIncrementalSearch = isNone then
    begin
      StopTimer(SearchTimer);
      FSearchBuffer := '';
      FLastSearchNode := nil;
    end;
  end;
end;

procedure TBaseVirtualTree.SetSelected(Node: PVirtualNode; Value: Boolean);

begin
  if not FSelectionLocked and Assigned(Node) and (Node <> FRoot) and (Value xor (vsSelected in Node.States)) then
  begin
    if Value then
    begin
      if FSelectionCount = 0 then
        FRangeAnchor := Node
      else
        if not (toMultiSelect in FOptions.FSelectionOptions) then
          ClearSelection;

      AddToSelection(Node);
      
      if ((FFocusedColumn < 0) or not (coVisible in FHeader.Columns[FFocusedColumn].Options)) and
        (FHeader.MainColumn > NoColumn) then
        if ([coVisible, coAllowFocus] *  FHeader.Columns[FHeader.MainColumn].Options = [coVisible, coAllowFocus]) then
          FFocusedColumn := FHeader.MainColumn
        else
          FFocusedColumn := FHeader.Columns.GetFirstVisibleColumn(True);
      if FRangeAnchor = nil then
        FRangeAnchor := Node;
    end
    else
    begin
      RemoveFromSelection(Node);
      if FSelectionCount = 0 then
        ResetRangeAnchor;
    end;
    if FullyVisible[Node] and not IsEffectivelyFiltered[Node] then
      InvalidateNode(Node);
  end;
end;

procedure TBaseVirtualTree.SetSelectionCurveRadius(const Value: Cardinal);

begin
  if FSelectionCurveRadius <> Value then
  begin
    FSelectionCurveRadius := Value;
    if HandleAllocated and not (csLoading in ComponentState) then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetStateImages(const Value: TCustomImageList);

begin
  if FStateImages <> Value then
  begin
    if Assigned(FStateImages) then
    begin
      FStateImages.UnRegisterChanges(FStateChangeLink);
      FStateImages.RemoveFreeNotification(Self);
    end;
    FStateImages := Value;
    if Assigned(FStateImages) then
    begin
      FStateImages.RegisterChanges(FStateChangeLink);
      FStateImages.FreeNotification(Self);
    end;
    if HandleAllocated and not (csLoading in ComponentState) then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetTextMargin(Value: Integer);

begin
  if FTextMargin <> Value then
  begin
    FTextMargin := Value;
    if not (csLoading in ComponentState) then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.SetTopNode(Node: PVirtualNode);

var
  R: TRect;
  Run: PVirtualNode;

begin
  if Assigned(Node) then
  begin
    
    Run := Node.Parent;
    while Run <> FRoot do
    begin
      if not (vsExpanded in Run.States) then
        ToggleNode(Run);
      Run := Run.Parent;
    end;
    R := GetDisplayRect(Node, FHeader.MainColumn, True);
    SetOffsetY(FOffsetY - R.Top);
  end;
end;

procedure TBaseVirtualTree.SetUpdateState(Updating: Boolean);

begin
  
  if Visible and HandleAllocated and (FUpdateCount = 0) then
    SendMessage(Handle, WM_SETREDRAW, Ord(not Updating), 0);
end;

procedure TBaseVirtualTree.SetVerticalAlignment(Node: PVirtualNode; Value: Byte);

begin
  if Value > 100 then
    Value := 100;
  if Node.Align <> Value then
  begin
    Node.Align := Value;
    if FullyVisible[Node] and not IsEffectivelyFiltered[Node] then
      InvalidateNode(Node);
  end;
end;

procedure TBaseVirtualTree.SetVisible(Node: PVirtualNode; Value: Boolean);

var
  NeedUpdate: Boolean;

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Invalid parameter.');

  if Value <> (vsVisible in Node.States) then
  begin
    InterruptValidation;
    NeedUpdate := False;
    if Value then
    begin
      Include(Node.States, vsVisible);
      if vsExpanded in Node.Parent.States then
        AdjustTotalHeight(Node.Parent, Node.TotalHeight, True);
      if VisiblePath[Node] then
      begin
        Inc(FVisibleCount, CountVisibleChildren(Node) + Cardinal(IfThen(IsEffectivelyVisible[Node], 1)));
        NeedUpdate := True;
      end;
      
      if not IsEffectivelyFiltered[Node] then
        Exclude(Node.Parent.States, vsAllChildrenHidden);
    end
    else
    begin
      if vsExpanded in Node.Parent.States then
        AdjustTotalHeight(Node.Parent, -Integer(Node.TotalHeight), True);
      if VisiblePath[Node] then
      begin
        Dec(FVisibleCount, CountVisibleChildren(Node) + Cardinal(IfThen(IsEffectivelyVisible[Node], 1)));
        NeedUpdate := True;
      end;
      Exclude(Node.States, vsVisible);

      if FUpdateCount = 0 then
        DetermineHiddenChildrenFlag(Node.Parent)
      else
        Include(FStates, tsUpdateHiddenChildrenNeeded)
    end;

    InvalidateCache;
    if NeedUpdate and (FUpdateCount = 0) then
    begin
      ValidateCache;
      UpdateScrollBars(True);
      Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.SetVisiblePath(Node: PVirtualNode; Value: Boolean);

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Invalid parameter.');

  if Value then
  begin
    repeat
      Node := Node.Parent;
      if Node = FRoot then
        Break;
      if not (vsExpanded in Node.States) then
        ToggleNode(Node);
    until False;
  end;
end;

procedure TBaseVirtualTree.StaticBackground(Source: TBitmap; Target: TCanvas; OffsetPosition: TPoint; R: TRect);

const
  DST = $00AA0029; 

var
  PicRect: TRect;
  AreaRect: TRect;
  DrawRect: TRect;

begin
  
  Target.Brush.Color := Color;
  Target.FillRect(R);
  
  PicRect := Rect(FBackgroundOffsetX, FBackgroundOffsetY, FBackgroundOffsetX + Source.Width, FBackgroundOffsetY + Source.Height);
  
  AreaRect := Rect(OffsetPosition.X + R.Left, OffsetPosition.Y + R.Top, OffsetPosition.X + R.Right, OffsetPosition.Y + R.Bottom);
  
  if IntersectRect(DrawRect, PicRect, AreaRect) then
  begin
    
    if Source.Transparent then
    begin
      
      MaskBlt(Target.Handle, DrawRect.Left - OffsetPosition.X, DrawRect.Top - OffsetPosition.Y, (DrawRect.Right - OffsetPosition.X) - (DrawRect.Left - OffsetPosition.X),
        (DrawRect.Bottom - OffsetPosition.Y) - (DrawRect.Top - OffsetPosition.Y), Source.Canvas.Handle, DrawRect.Left - PicRect.Left, DrawRect.Top - PicRect.Top,
        Source.MaskHandle, DrawRect.Left - PicRect.Left, DrawRect.Top - PicRect.Top, MakeROP4(DST, SRCCOPY));
    end
    else
    begin
      
      BitBlt(Target.Handle, DrawRect.Left - OffsetPosition.X, DrawRect.Top - OffsetPosition.Y, (DrawRect.Right - OffsetPosition.X) - (DrawRect.Left - OffsetPosition.X),
        (DrawRect.Bottom - OffsetPosition.Y) - (DrawRect.Top - OffsetPosition.Y) + R.Top, Source.Canvas.Handle, DrawRect.Left - PicRect.Left, DrawRect.Top - PicRect.Top,
        SRCCOPY);
    end;
  end;
end;

procedure TBaseVirtualTree.StopTimer(ID: Integer);

begin
  if HandleAllocated then
    KillTimer(Handle, ID);
end;

procedure TBaseVirtualTree.SetWindowTheme(Theme: Unicodestring);

begin
  FChangingTheme := True;
  UxTheme.SetWindowTheme(Handle, PWideChar(Theme), nil);
end;

procedure TBaseVirtualTree.TileBackground(Source: TBitmap; Target: TCanvas; Offset: TPoint; R: TRect);

var
  SourceX,
  SourceY,
  TargetX,
  DeltaY: Integer;

begin
  with Target do
  begin
    SourceY := (R.Top + Offset.Y + FBackgroundOffsetY) mod Source.Height;
    
    if SourceY < 0 then
      SourceY := Source.Height + SourceY;
    
    while R.Top < R.Bottom do
    begin
      SourceX := (R.Left + Offset.X + FBackgroundOffsetX) mod Source.Width;
      
      if SourceX < 0 then
        SourceX := Source.Width + SourceX;

      TargetX := R.Left;
      
      DeltaY := Min(R.Bottom - R.Top, Source.Height - SourceY);
      
      while TargetX < R.Right do
      begin
        BitBlt(Handle, TargetX, R.Top, Min(R.Right - TargetX, Source.Width - SourceX), DeltaY,
          Source.Canvas.Handle, SourceX, SourceY, SRCCOPY);
        Inc(TargetX, Source.Width - SourceX);
        SourceX := 0;
      end;
      Inc(R.Top, Source.Height - SourceY);
      SourceY := 0;
    end;
  end;
end;

function TBaseVirtualTree.ToggleCallback(Step, StepSize: Integer; Data: Pointer): Boolean;

var
  Column: TColumnIndex;
  Run: TRect;
  SecondaryStepSize: Integer;

  procedure EraseLine;

  var
    LocalBrush: HBRUSH;

  begin
    with TToggleAnimationData(Data^), FHeader.FColumns do
    begin
      
      Column := GetFirstVisibleColumn;
      while (Column > InvalidColumn) and (Run.Left < ClientWidth) do
      begin
        GetColumnBounds(Column, Run.Left, Run.Right);
        if coParentColor in Items[Column].FOptions then
          FillRect(DC, Run, Brush)
        else
        begin
          if VclStyleEnabled then
            LocalBrush := CreateSolidBrush(ColorToRGB(FColors.BackGroundColor))
          else
            LocalBrush := CreateSolidBrush(ColorToRGB(Items[Column].Color));
          FillRect(DC, Run, LocalBrush);
          DeleteObject(LocalBrush);
        end;
        Column := GetNextVisibleColumn(Column);
      end;
    end;
  end;

  procedure DoScrollUp(DC: HDC; Brush: HBRUSH; Area: TRect; Steps: Integer);

  begin
    ScrollDC(DC, 0, -Steps, Area, Area, 0, nil);

    if Step = 0 then
      if not FHeader.UseColumns then
        FillRect(DC, Rect(Area.Left, Area.Bottom - Steps - 1, Area.Right, Area.Bottom), Brush)
      else
      begin
        Run := Rect(Area.Left, Area.Bottom - Steps - 1, Area.Right, Area.Bottom);
        EraseLine;
      end;
  end;

  procedure DoScrollDown(DC: HDC; Brush: HBRUSH; Area: TRect; Steps: Integer);

  begin
    ScrollDC(DC, 0, Steps, Area, Area, 0, nil);

    if Step = 0 then
      if not FHeader.UseColumns then
        FillRect(DC, Rect(Area.Left, Area.Top, Area.Right, Area.Top + Steps + 1), Brush)
      else
      begin
        Run := Rect(Area.Left, Area.Top, Area.Right, Area.Top + Steps + 1);
        EraseLine;
      end;
  end;

begin
  Result := True;
  if StepSize > 0 then
  begin
    SecondaryStepSize := 0;
    with TToggleAnimationData(Data^) do
    begin
      if Mode1 <> tamNoScroll then
      begin
        if Mode1 = tamScrollUp then
          DoScrollUp(DC, Brush, R1, StepSize)
        else
          DoScrollDown(DC, Brush, R1, StepSize);

        if (Mode2 <> tamNoScroll) and (ScaleFactor > 0) then
        begin
          
          SecondaryStepSize := Round((StepSize + MissedSteps) * ScaleFactor);
          MissedSteps := MissedSteps + StepSize * ScaleFactor - SecondaryStepSize;
        end;
      end
      else
        SecondaryStepSize := StepSize;

      if Mode2 <> tamNoScroll then
        if Mode2 = tamScrollUp then
          DoScrollUp(DC, Brush, R2, SecondaryStepSize)
        else
          DoScrollDown(DC, Brush, R2, SecondaryStepSize);
    end;
  end;
end;

procedure TBaseVirtualTree.CMColorChange(var Message: TMessage);

begin
  if not (csLoading in ComponentState) then
  begin
    PrepareBitmaps(True, False);
    if HandleAllocated then
      Invalidate;
  end;
end;

procedure TBaseVirtualTree.CMCtl3DChanged(var Message: TMessage);

begin
  inherited;
  if FBorderStyle = bsSingle then
    RecreateWnd;
end;

procedure TBaseVirtualTree.CMBiDiModeChanged(var Message: TMessage);

begin
  inherited;

  if UseRightToLeftAlignment then
    FEffectiveOffsetX := Integer(FRangeX) - ClientWidth + FOffsetX
  else
    FEffectiveOffsetX := -FOffsetX;
  if FEffectiveOffsetX < 0 then
    FEffectiveOffsetX := 0;

  if toAutoBidiColumnOrdering in FOptions.FAutoOptions then
    FHeader.FColumns.ReorderColumns(UseRightToLeftAlignment);
  FHeader.Invalidate(nil);
end;

 {$if CompilerVersion >= 23 }
procedure TBaseVirtualTree.CMBorderChanged(var Message: TMessage);
begin
  inherited;
  
  if not FSetOrRestoreBevelKindAndBevelWidth then
  begin
    FSavedBevelKind := BevelKind;
    FSavedBorderWidth := BorderWidth;
  end;
end;

procedure TBaseVirtualTree.CMStyleChanged(var Message: TMessage);
begin
  VclStyleChanged;
  RecreateWnd;
end;

procedure TBaseVirtualTree.CMParentDoubleBufferedChange(var Message: TMessage);
begin
  
end;

{$ifend}

procedure TBaseVirtualTree.CMDenySubclassing(var Message: TMessage);

begin
  Message.Result := 1;
end;

procedure TBaseVirtualTree.CMDrag(var Message: TCMDrag);

var
  S: TObject;
  ShiftState: Integer;
  P: TPoint;
  Formats: TFormatArray;
  Effect: Integer;

begin
  with Message, DragRec^ do
  begin
    S := Source;
    Formats := nil;
    
    if S is TDragDockObject then
      inherited
    else
    begin
      
      if not (tsUserDragObject in FStates) and (S is TBaseDragControlObject) then
        S := (S as TBaseDragControlObject).Control;
      case DragMessage of
        dmDragEnter, dmDragLeave, dmDragMove:
          begin
            if DragMessage = dmDragEnter then
              DoStateChange([tsVCLDragging]);
            if DragMessage = dmDragLeave then
              DoStateChange([tsVCLDragFinished], [tsVCLDragging]);

            if DragMessage = dmDragMove then
              with ScreenToClient(Pos) do
                DoAutoScroll(X, Y);

            ShiftState := 0;
            
            if GetKeyState(VK_SHIFT) < 0 then
              ShiftState := ShiftState or MK_SHIFT;
            if GetKeyState(VK_CONTROL) < 0 then
              ShiftState := ShiftState or MK_CONTROL;
            
            Effect := DROPEFFECT_MOVE or DROPEFFECT_COPY;
            DragOver(S, ShiftState, TDragState(DragMessage), Pos, Effect);
            FLastVCLDragTarget := FDropTargetNode;
            FVCLDragEffect := Effect;
            if (DragMessage = dmDragLeave) and Assigned(FDropTargetNode) then
            begin
              InvalidateNode(FDropTargetNode);
              FDropTargetNode := nil;
            end;
            Result := LRESULT(Effect);
          end;
        dmDragDrop:
          begin
            ShiftState := 0;
            
            if GetKeyState(VK_SHIFT) < 0 then
              ShiftState := ShiftState or MK_SHIFT;
            if GetKeyState(VK_CONTROL) < 0 then
              ShiftState := ShiftState or MK_CONTROL;
            
            if Assigned(FDropTargetNode) then
              InvalidateNode(FDropTargetNode);
            FDropTargetNode := FLastVCLDragTarget;
            P := Point(Pos.X, Pos.Y);
            P := ScreenToClient(P);
            try
              DoDragDrop(S, nil, Formats, KeysToShiftState(ShiftState), P, FVCLDragEffect, FLastDropMode);
            finally
              if Assigned(FDropTargetNode) then
              begin
                InvalidateNode(FDropTargetNode);
                FDropTargetNode := nil;
              end;
            end;
          end;
        dmFindTarget:
          begin
            Result := LRESULT(ControlAtPos(ScreenToClient(Pos), False));
            if Result = 0 then
              Result := LRESULT(Self);
            
            if tsVCLDragPending in FStates then
              DoStateChange([tsVCLDragging], [tsVCLDragPending, tsEditPending, tsClearPending]);
          end;
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.CMEnabledChanged(var Message: TMessage);

begin
  inherited;
  
  if csDesigning in ComponentState then
    RedrawWindow(Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_NOERASE or RDW_NOCHILDREN);
end;

procedure TBaseVirtualTree.CMFontChanged(var Message: TMessage);

var
  HeaderMessage: TMessage;

begin
  inherited;

  if not (csLoading in ComponentState) then
  begin
    PrepareBitmaps(True, False);
    if HandleAllocated then
      Invalidate;
  end;

  HeaderMessage.Msg := CM_PARENTFONTCHANGED;
  HeaderMessage.WParam := 0;
  HeaderMessage.LParam := 0;
  HeaderMessage.Result := 0;
  FHeader.HandleMessage(HeaderMessage);
end;

procedure TBaseVirtualTree.CMHintShow(var Message: TCMHintShow);

var
  NodeRect: TRect;
  SpanColumn,
  Dummy,
  ColLeft,
  ColRight: Integer;
  HitInfo: THitInfo;
  ShowOwnHint: Boolean;
  IsFocusedOrEditing: Boolean;
  ParentForm: TCustomForm;
  BottomRightCellContentMargin: TPoint;
  DummyLineBreakStyle: TVTTooltipLineBreakStyle;
  HintKind: TVTHintKind;
begin
  with Message do
  begin
    Result := 1;

    if PtInRect(FLastHintRect, HintInfo.CursorPos) then
      Exit;
    
    with HintInfo^ do
      GetHitTestInfoAt(CursorPos.X, CursorPos.Y, True, HitInfo);
    
    if IsEditing then
      IsFocusedOrEditing := HitInfo.HitNode <> FFocusedNode
    else
    begin
      IsFocusedOrEditing := Focused;
      ParentForm := GetParentForm(Self);
      if Assigned(ParentForm) then
        IsFocusedOrEditing := ParentForm.Focused or Application.Active;
    end;

    if (GetCapture = 0) and ShowHint and not (Dragging or IsMouseSelecting) and ([tsScrolling] * FStates = []) and
      (FHeader.States = []) and IsFocusedOrEditing then
    begin
      with HintInfo^ do
      begin
        Result := 0;
        ShowOwnHint := False;
        
        if GetHintWindowClass.InheritsFrom(TVirtualTreeHintWindow) then
          HintStr := ' '
        else
        begin
          
          HintStr := '';
          if FHeader.UseColumns and (hoShowHint in FHeader.FOptions) and FHeader.InHeader(CursorPos) then
          begin
            CursorRect := FHeaderRect;
            
            OffsetRect(CursorRect, 0, -Integer(FHeader.FHeight));
            HitInfo.HitColumn := FHeader.FColumns.GetColumnAndBounds(CursorPos, CursorRect.Left, CursorRect.Right);
            if (HitInfo.HitColumn > -1) and not (csLButtonDown in ControlState) and
              (FHeader.FColumns[HitInfo.HitColumn].FHint <> '') then
              HintStr := FHeader.FColumns[HitInfo.HitColumn].FHint;
          end
          else
          if HintMode = hmDefault then
            HintStr := GetShortHint(Hint)
          else
          if Assigned(HitInfo.HitNode) and (HitInfo.HitColumn > InvalidColumn) then
          begin
            if HintMode = hmToolTip then
              HintStr := DoGetNodeToolTip(HitInfo.HitNode, HitInfo.HitColumn, DummyLineBreakStyle)
            else
              HintStr := DoGetNodeHint(HitInfo.HitNode, HitInfo.HitColumn, DummyLineBreakStyle);
          end;
        end;
        
        if FHeader.UseColumns and (hoShowHint in FHeader.FOptions) and FHeader.InHeader(CursorPos) then
        begin
          CursorRect := FHeaderRect;
          
          OffsetRect(CursorRect, 0, -Integer(FHeader.FHeight));
          HitInfo.HitColumn := FHeader.FColumns.GetColumnAndBounds(CursorPos, CursorRect.Left, CursorRect.Right);
          
          HintPos.Y := Max(HintPos.Y, ClientToScreen(Point(0, CursorRect.Bottom)).Y);
          
          if (HitInfo.HitColumn > -1) and not (csLButtonDown in ControlState) then
          begin
            FHintData.DefaultHint := FHeader.FColumns[HitInfo.HitColumn].FHint;
            if FHintData.DefaultHint <> '' then
              ShowOwnHint := True
            else
              Result := 1;
          end
          else
            Result := 1;
        end
        else
        begin
          
          if FHintMode = hmDefault then
            HintStr := GetShortHint(Hint)
          else
          begin
            if Assigned(HitInfo.HitNode) and (HitInfo.HitColumn > InvalidColumn) then
            begin
              
              DoGetHintKind(HitInfo.HitNode, HitInfo.HitColumn, HintKind);
              FHintData.HintRect := Rect(0, 0, 0, 0);
              if (HintKind = vhkOwnerDraw) then
              begin
                DoGetHintSize(HitInfo.HitNode, HitInfo.HitColumn, FHintData.HintRect);
                ShowOwnHint := not IsRectEmpty(FHintData.HintRect);
              end
              else
                
                ShowOwnHint := true;

              if ShowOwnHint then
              begin
                if HitInfo.HitColumn > NoColumn then
                begin
                  FHeader.FColumns.GetColumnBounds(HitInfo.HitColumn, ColLeft, ColRight);
                  
                  if toAutoSpanColumns in FOptions.FAutoOptions then
                  begin
                    SpanColumn := HitInfo.HitColumn;
                    repeat
                      Dummy := FHeader.FColumns.GetNextVisibleColumn(SpanColumn);
                      if (Dummy = InvalidColumn) or not ColumnIsEmpty(HitInfo.HitNode, Dummy) then
                        Break;
                      SpanColumn := Dummy;
                    until False;
                    if SpanColumn <> HitInfo.HitColumn then
                      FHeader.FColumns.GetColumnBounds(SpanColumn, Dummy, ColRight);
                  end;
                end
                else
                begin
                  ColLeft := 0;
                  ColRight := ClientWidth;
                end;

                FHintData.DefaultHint :=  '';
                if FHintMode <> hmTooltip then
                begin
                  
                  CursorRect := GetDisplayRect(HitInfo.HitNode, HitInfo.HitColumn, False);
                  CursorRect.Left := ColLeft;
                  CursorRect.Right := ColRight;
                  
                  HintPos.Y := Max(HintPos.Y, ClientToScreen(CursorRect.BottomRight).Y) + 2;
                end
                else
                begin
                  
                  if vsMultiline in HitInfo.HitNode.States then
                  begin
                    if hiOnItemLabel in HitInfo.HitPositions then
                    begin
                      ShowOwnHint := True;
                      NodeRect := GetDisplayRect(HitInfo.HitNode, HitInfo.HitColumn, True, False);
                    end;
                  end
                  else
                  begin
                    NodeRect := GetDisplayRect(HitInfo.HitNode, HitInfo.HitColumn, True, True, True);
                    BottomRightCellContentMargin := DoGetCellContentMargin(HitInfo.HitNode, HitInfo.HitColumn, ccmtBottomRightOnly);

                    ShowOwnHint := (HitInfo.HitColumn > InvalidColumn) and PtInRect(NodeRect, CursorPos) and
                      (CursorPos.X <= ColRight) and (CursorPos.X >= ColLeft) and
                      (
                        
                        ( (NodeRect.Right + BottomRightCellContentMargin.X) > Min(ColRight - 1, ClientWidth) ) or
                        (NodeRect.Left < Max(ColLeft, 0)) or
                        ( (NodeRect.Bottom + BottomRightCellContentMargin.Y) > ClientHeight ) or
                        (NodeRect.Top < 0)
                      );
                  end;

                  if ShowOwnHint then
                  begin
                    
                    FHintData.DefaultHint := '';
                    HintPos := ClientToScreen(Point(NodeRect.Left, NodeRect.Top));
                    CursorRect := NodeRect;
                  end
                  else
                    
                    Result := 1;
                end;
              end
              else
                Result := 1; 
            end
            else
            begin
              
              if FHintMode = hmHintAndDefault then
              begin
                FHintData.DefaultHint := GetShortHint(Hint);
                if Length(FHintData.DefaultHint) = 0 then
                  Result := 1
                else
                  ShowOwnHint := True;
              end
              else
                Result := 1;
            end;
          end;
        end;
        
        if ShowOwnHint and (Result = 0) then
        begin
          HintWindowClass := GetHintWindowClass;

          FHintData.Tree := Self;
          FHintData.Column := HitInfo.HitColumn;
          FHintData.Node := HitInfo.HitNode;
          FLastHintRect := CursorRect;
          HintData := @FHintData;
        end
        else
          FLastHintRect := Rect(0, 0, 0, 0);
      end;
      
      if Result = 0 then
        DoStateChange([tsHint])
      else
        DoStateChange([], [tsHint]);
    end;
  end;
end;

procedure TBaseVirtualTree.CMHintShowPause(var Message: TCMHintShowPause);

var
  P: TPoint;

begin
  
  if FHintWindowDestroyed then
  begin
    GetCursorPos(P);
    
    if FHeader.UseColumns and (hoShowHint in FHeader.FOptions) and FHeader.InHeader(ScreenToClient(P)) or
      (FHintMode = hmToolTip) then
      Message.Pause^ := 0
  end
  else
    if FHintMode = hmToolTip then
      Message.Pause^ := 0;
end;

procedure TBaseVirtualTree.CMMouseEnter(var Message: TMessage);
begin
  DoMouseEnter();
end;

procedure TBaseVirtualTree.CMMouseLeave(var Message: TMessage);

var
  LeaveStates: TVirtualTreeStates;

begin
  
  if Assigned(FHintData.Tree) then
    FHintData.Tree.FLastHintRect := Rect(0, 0, 0, 0);

  LeaveStates := [tsHint];
  if [tsWheelPanning, tsWheelScrolling] * FStates = [] then
  begin
    StopTimer(ScrollTimer);
    LeaveStates := LeaveStates + [tsScrollPending, tsScrolling];
  end;
  DoStateChange([], LeaveStates);
  if Assigned(FCurrentHotNode) then
  begin
    DoHotChange(FCurrentHotNode, nil);
    if (toHotTrack in FOptions.PaintOptions) or (toCheckSupport in FOptions.FMiscOptions) then
      InvalidateNode(FCurrentHotNode);
    FCurrentHotNode := nil;
  end;

  if Assigned(Header) then
  begin
    Header.FColumns.FDownIndex := NoColumn;
    Header.FColumns.FHoverIndex := NoColumn;
    Header.FColumns.FCheckBoxHit := False;
  end;
  DoMouseLeave();
  inherited;
end;

procedure TBaseVirtualTree.CMMouseWheel(var Message: TCMMouseWheel);

var
  ScrollAmount: Integer;
  ScrollLines: DWORD;
  RTLFactor: Integer;
  WheelFactor: Double;

begin
  StopWheelPanning;

  inherited;

  if Message.Result = 0  then
  begin
    with Message do
    begin
      Result := 1;
      WheelFactor := WheelDelta / WHEEL_DELTA;
      if (FRangeY > Cardinal(ClientHeight)) and (not (ssShift in ShiftState)) then
      begin
        
        if ssCtrl in ShiftState then
          ScrollAmount := Trunc(WheelFactor * ClientHeight)
        else
        begin
          SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @ScrollLines, 0);
          if ScrollLines = WHEEL_PAGESCROLL then
            ScrollAmount := Trunc(WheelFactor * ClientHeight)
          else
            ScrollAmount := Trunc(WheelFactor * ScrollLines * FDefaultNodeHeight);
        end;
        SetOffsetY(FOffsetY + ScrollAmount);
      end
      else
      begin
        
        if UseRightToLeftAlignment then
          RTLFactor := -1
        else
          RTLFactor := 1;

        if ssCtrl in ShiftState then
          ScrollAmount := Trunc(WheelFactor * (ClientWidth - FHeader.Columns.GetVisibleFixedWidth))
        else
        begin
          SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @ScrollLines, 0);
          ScrollAmount := Trunc(WheelFactor * ScrollLines * FHeader.Columns.GetScrollWidth);
        end;
        SetOffsetX(FOffsetX + RTLFactor * ScrollAmount);
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.CMSysColorChange(var Message: TMessage);

begin
  inherited;

  ConvertImageList(LightCheckImages, 'VT_CHECK_LIGHT');
  ConvertImageList(DarkCheckImages, 'VT_CHECK_DARK');
  ConvertImageList(LightTickImages, 'VT_TICK_LIGHT');
  ConvertImageList(DarkTickImages, 'VT_TICK_DARK');
  ConvertImageList(FlatImages, 'VT_FLAT');
  ConvertImageList(UtilityImages, 'VT_UTILITIES');
  
  Message.Msg := WM_SYSCOLORCHANGE;
  DefaultHandler(Message);
end;

procedure TBaseVirtualTree.TVMGetItem(var Message: TMessage);

const
  StateMask = TVIS_STATEIMAGEMASK or TVIS_OVERLAYMASK or TVIS_EXPANDED or TVIS_DROPHILITED or TVIS_CUT or
    TVIS_SELECTED or TVIS_FOCUSED;

var
  Item: PTVItemEx;
  Node: PVirtualNode;
  Ghosted: Boolean;
  ImageIndex: Integer;
  R: TRect;
  Text: UnicodeString;
  {$ifndef UNICODE}
    ANSIText: ANSIString;
  {$endif}

begin
  
  Item := Pointer(Message.LParam);
  Message.Result := Ord(((Item.mask and TVIF_HANDLE) <> 0) and Assigned(Item.hItem));
  if Message.Result = 1 then
  begin
    Node := Pointer(Item.hItem);
    
    if (Item.mask and TVIF_CHILDREN) <> 0 then
      Item.cChildren := Node.ChildCount;
    
    if (Item.mask and TVIF_IMAGE) <> 0 then
    begin
      Item.iImage := -1;
      DoGetImageIndex(Node, ikNormal, -1, Ghosted, Item.iImage);
    end;
    
    if (Item.mask and TVIF_SELECTEDIMAGE) <> 0 then
    begin
      Item.iSelectedImage := -1;
      DoGetImageIndex(Node, ikSelected, -1, Ghosted, Item.iSelectedImage);
    end;
    
    if (Item.mask and TVIF_STATE) <> 0 then
    begin
      
      Item.stateMask := StateMask;
      Item.state := 0;
      if Node = FFocusedNode then
        Item.state := Item.state or TVIS_FOCUSED;
      if vsSelected in Node.States then
        Item.state := Item.state or TVIS_SELECTED;
      if vsCutOrCopy in Node.States then
        Item.state := Item.state or TVIS_CUT;
      if Node = FDropTargetNode then
        Item.state := Item.state or TVIS_DROPHILITED;
      if vsExpanded in Node.States then
        Item.state := Item.state or TVIS_EXPANDED;
      
      ImageIndex := -1;
      DoGetImageIndex(Node, ikState, -1, Ghosted, ImageIndex);
      Item.state := Item.state or Byte(IndexToStateImageMask(ImageIndex + 1));
      ImageIndex := -1;
      DoGetImageIndex(Node, ikOverlay, -1, Ghosted, ImageIndex);
      Item.state := Item.state or Byte(IndexToOverlayMask(ImageIndex + 1));
    end;
    
    if (Item.mask and TVIF_TEXT) <> 0 then
    begin
      GetTextInfo(Node, -1, Font, R, Text);

      {$ifdef UNICODE}
        StrLCopy(Item.pszText, PWideChar(Text), Item.cchTextMax - 1);
        Item.pszText[Length(Text)] := #0;
      {$else}
        
        ANSIText := Text;
        StrLCopy(Item.pszText, PChar(ANSIText), Item.cchTextMax - 1);
        Item.pszText[Length(ANSIText)] := #0;
      {$endif}
    end;
  end;
end;

procedure TBaseVirtualTree.TVMGetItemRect(var Message: TMessage);

var
  TextOnly: Boolean;
  Node: PVirtualNode;

begin
  
  Node := Pointer(Pointer(Message.LParam)^);
  Message.Result := Ord(IsVisible[Node]);
  if Message.Result <> 0 then
  begin
    TextOnly := Message.WParam <> 0;
    PRect(Message.LParam)^ := GetDisplayRect(Node, -1, TextOnly);
  end;
end;

procedure TBaseVirtualTree.TVMGetNextItem(var Message: TMessage);

var
  Node: PVirtualNode;

begin
  
  Message.Result := 0;
  Node := Pointer(Message.LParam);
  case Message.WParam of
    TVGN_CARET:
      Message.Result := LRESULT(FFocusedNode);
    TVGN_CHILD:
      if Assigned(Node) then
        Message.Result := LRESULT(GetFirstChild(Node));
    TVGN_DROPHILITE:
      Message.Result := LRESULT(FDropTargetNode);
    TVGN_FIRSTVISIBLE:
      Message.Result := LRESULT(GetFirstVisible(nil, True));
    TVGN_LASTVISIBLE:
      Message.Result := LRESULT(GetLastVisible(nil, True));
    TVGN_NEXT:
      if Assigned(Node) then
        Message.Result := LRESULT(GetNextSibling(Node));
    TVGN_NEXTVISIBLE:
      if Assigned(Node) then
        Message.Result := LRESULT(GetNextVisible(Node, True));
    TVGN_PARENT:
      if Assigned(Node) and (Node <> FRoot) and (Node.Parent <> FRoot) then
        Message.Result := LRESULT(Node.Parent);
    TVGN_PREVIOUS:
      if Assigned(Node) then
        Message.Result := LRESULT(GetPreviousSibling(Node));
    TVGN_PREVIOUSVISIBLE:
      if Assigned(Node) then
        Message.Result := LRESULT(GetPreviousVisible(Node, True));
    TVGN_ROOT:
      Message.Result := LRESULT(GetFirst);
  end;
end;

procedure TBaseVirtualTree.WMCancelMode(var Message: TWMCancelMode);

begin
  
  StopTimer(ExpandTimer);
  StopTimer(EditTimer);
  StopTimer(HeaderTimer);
  StopTimer(ScrollTimer);
  StopTimer(SearchTimer);
  StopTimer(ThemeChangedTimer);
  FSearchBuffer := '';
  FLastSearchNode := nil;

  DoStateChange([], [tsClearPending, tsEditPending, tsOLEDragPending, tsVCLDragPending, tsDrawSelecting,
    tsDrawSelPending, tsIncrementalSearching]);

  inherited;
end;

procedure TBaseVirtualTree.WMChangeState(var Message: TMessage);

var
  EnterStates,
  LeaveStates: TVirtualTreeStates;

begin
  EnterStates := [];
  if csStopValidation in TChangeStates(Byte(Message.WParam)) then
    Include(EnterStates, tsStopValidation);
  if csUseCache in TChangeStates(Byte(Message.WParam)) then
    Include(EnterStates, tsUseCache);
  if csValidating in TChangeStates(Byte(Message.WParam)) then
    Include(EnterStates, tsValidating);
  if csValidationNeeded in TChangeStates(Byte(Message.WParam)) then
    Include(EnterStates, tsValidationNeeded);

  LeaveStates := [];
  if csStopValidation in TChangeStates(Byte(Message.LParam)) then
    Include(LeaveStates, tsStopValidation);
  if csUseCache in TChangeStates(Byte(Message.LParam)) then
    Include(LeaveStates, tsUseCache);
  if csValidating in TChangeStates(Byte(Message.LParam)) then
    Include(LeaveStates, tsValidating);
  if csValidationNeeded in TChangeStates(Byte(Message.LParam)) then
    Include(LeaveStates, tsValidationNeeded);

  DoStateChange(EnterStates, LeaveStates);
end;

procedure TBaseVirtualTree.WMChar(var Message: TWMChar);

begin
  if tsIncrementalSearchPending in FStates then
  begin
    HandleIncrementalSearch(Message.CharCode);
    DoStateChange([], [tsIncrementalSearchPending]);
  end;

  inherited;
end;

procedure TBaseVirtualTree.WMContextMenu(var Message: TWMContextMenu);

begin
  DoStateChange([], [tsClearPending, tsEditPending, tsOLEDragPending, tsVCLDragPending]);

  if not (tsPopupMenuShown in FStates) then
    inherited;
end;

procedure TBaseVirtualTree.WMCopy(var Message: TWMCopy);

begin
  CopyToClipboard;
end;

procedure TBaseVirtualTree.WMCut(var Message: TWMCut);

begin
  CutToClipboard;
end;

procedure TBaseVirtualTree.WMEnable(var Message: TWMEnable);

begin
  inherited;
  RedrawWindow(Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_NOERASE or RDW_NOCHILDREN);
end;

procedure TBaseVirtualTree.WMEraseBkgnd(var Message: TWMEraseBkgnd);

begin
  Message.Result := 1;
end;

procedure TBaseVirtualTree.WMGetDlgCode(var Message: TWMGetDlgCode);

begin
  Message.Result := DLGC_WANTCHARS or DLGC_WANTARROWS;
  if FWantTabs then
    Message.Result := Message.Result or DLGC_WANTTAB;
end;

procedure TBaseVirtualTree.WMGetObject(var Message: TMessage);

begin
  if GetAccessibilityFactory <> nil then
  begin
    
    if FAccessible = nil then
      FAccessible := GetAccessibilityFactory.CreateIAccessible(Self);
    if FAccessibleItem = nil then
      FAccessibleItem := GetAccessibilityFactory.CreateIAccessible(Self);
    if Cardinal(Message.LParam) = OBJID_CLIENT then
      {$if CompilerVersion >= 18}
      if Assigned(Accessible) then
        Message.Result := LresultFromObject(IID_IAccessible, Message.WParam, FAccessible)
      else
      {$ifend}
        Message.Result := 0;
  end;
end;

procedure TBaseVirtualTree.WMHScroll(var Message: TWMHScroll);

  function GetRealScrollPosition: Integer;

  var
    SI: TScrollInfo;
    Code: Integer;

  begin
    SI.cbSize := SizeOf(TScrollInfo);
    SI.fMask := SIF_TRACKPOS;
    Code := SB_HORZ;
    GetScrollInfo(Handle, Code, SI);
    Result := SI.nTrackPos;
  end;

var
  RTLFactor: Integer;

begin
  if UseRightToLeftAlignment then
    RTLFactor := -1
  else
    RTLFactor := 1;

  case Message.ScrollCode of
    SB_BOTTOM:
      SetOffsetX(-Integer(FRangeX));
    SB_ENDSCROLL:
      begin
        DoStateChange([], [tsThumbTracking]);
        
        UpdateHorizontalScrollBar(False);
      end;
    SB_LINELEFT:
      SetOffsetX(FOffsetX + RTLFactor * FScrollBarOptions.FIncrementX);
    SB_LINERIGHT:
      SetOffsetX(FOffsetX - RTLFactor * FScrollBarOptions.FIncrementX);
    SB_PAGELEFT:
      SetOffsetX(FOffsetX + RTLFactor * (ClientWidth - FHeader.Columns.GetVisibleFixedWidth));
    SB_PAGERIGHT:
      SetOffsetX(FOffsetX - RTLFactor * (ClientWidth - FHeader.Columns.GetVisibleFixedWidth));
    SB_THUMBPOSITION,
    SB_THUMBTRACK:
      begin
        DoStateChange([tsThumbTracking]);
        if UseRightToLeftAlignment then
          SetOffsetX(-Integer(FRangeX) + ClientWidth + GetRealScrollPosition)
        else
          SetOffsetX(-GetRealScrollPosition);
      end;
    SB_TOP:
      SetOffsetX(0);
  end;

  Message.Result := 0;
end;

procedure TBaseVirtualTree.WMKeyDown(var Message: TWMKeyDown);

var
  Shift: TShiftState;
  Node, Temp,
  LastFocused: PVirtualNode;
  Offset: Integer;
  ClearPending,
  NeedInvalidate,
  DoRangeSelect,
  HandleMultiSelect: Boolean;
  Context: Integer;
  ParentControl: TWinControl;
  R: TRect;
  NewCheckState: TCheckState;
  TempColumn,
  NewColumn: TColumnIndex;
  ActAsGrid: Boolean;
  ForceSelection: Boolean;
  NewWidth,
  NewHeight: Integer;
  RTLFactor: Integer;
  
  GetStartColumn: function(ConsiderAllowFocus: Boolean = False): TColumnIndex of object;
  GetNextColumn: function(Column: TColumnIndex; ConsiderAllowFocus: Boolean = False): TColumnIndex of object;
  GetNextNode: TGetNextNodeProc;

  KeyState: TKeyboardState;
  Buffer: array[0..1] of AnsiChar;

begin
  
  inherited;

  with Message do
  begin
    Shift := KeyDataToShiftState(KeyData);
    
    if DoKeyAction(CharCode, Shift) then
    begin
      if (tsKeyCheckPending in FStates) and (CharCode <> VK_SPACE) then
      begin
        DoStateChange([], [tskeyCheckPending]);
        FCheckNode.CheckState := UnpressedState[FCheckNode.CheckState];
        RepaintNode(FCheckNode);
        FCheckNode := nil;
      end;

      if (CharCode in [VK_HOME, VK_END, VK_PRIOR, VK_NEXT, VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_BACK, VK_TAB]) and (RootNode.FirstChild<>nil) then
      begin
        HandleMultiSelect := (ssShift in Shift) and (toMultiSelect in FOptions.FSelectionOptions) and not IsEditing;
        
        DoRangeSelect := (CharCode in [VK_HOME, VK_END, VK_PRIOR, VK_NEXT]) and HandleMultiSelect and not IsEditing;

        NeedInvalidate := DoRangeSelect or (FSelectionCount > 1);
        ActAsGrid := toGridExtensions in FOptions.FMiscOptions;
        ClearPending := (Shift = []) or (ActAsGrid and not (ssShift in Shift)) or
          not (toMultiSelect in FOptions.FSelectionOptions) or (CharCode in [VK_TAB, VK_BACK]);
        
        LastFocused := FFocusedNode;
        if (LastFocused = nil) and (Shift <> []) then
          LastFocused := GetFirstVisible(nil, True);
        
        if FRangeAnchor = nil then
          FRangeAnchor := GetFirstSelected;
        if FRangeAnchor = nil then
          FRangeAnchor := GetFirst;

        if UseRightToLeftAlignment then
          RTLFactor := -1
        else
          RTLFactor := 1;
        
        case CharCode of
          VK_HOME, VK_END:
            begin
              if (CharCode = VK_END) xor UseRightToLeftAlignment then
              begin
                GetStartColumn := FHeader.FColumns.GetLastVisibleColumn;
                GetNextColumn := FHeader.FColumns.GetPreviousVisibleColumn;
                GetNextNode := GetPreviousVisible;
                Node := GetLastVisible(nil, True);
              end
              else
              begin
                GetStartColumn := FHeader.FColumns.GetFirstVisibleColumn;
                GetNextColumn := FHeader.FColumns.GetNextVisibleColumn;
                GetNextNode := GetNextVisible;
                Node := GetFirstVisible(nil, True);
              end;
              
              if FHeader.UseColumns then
                NewColumn := GetStartColumn
              else
                NewColumn := NoColumn;
              
              while (NewColumn > NoColumn) and not DoFocusChanging(FFocusedNode, FFocusedNode, FFocusedColumn, NewColumn) do
                NewColumn := GetNextColumn(NewColumn);
              if NewColumn > InvalidColumn then
              begin
                if (Shift = [ssCtrl]) and not ActAsGrid then
                begin
                  ScrollIntoView(Node, toCenterScrollIntoView in FOptions.SelectionOptions,
                    not (toDisableAutoscrollOnFocus in FOptions.FAutoOptions));
                  if (CharCode = VK_HOME) and not UseRightToLeftAlignment then
                    SetOffsetX(0)
                  else
                    SetOffsetX(-MaxInt);
                end
                else
                begin
                  if not ActAsGrid or (ssCtrl in Shift) then
                    FocusedNode := Node;
                  if ActAsGrid and not (toFullRowSelect in FOptions.FSelectionOptions) then
                    FocusedColumn := NewColumn;
                end;
              end;
            end;
          VK_PRIOR:
            if Shift = [ssCtrl, ssShift] then
              SetOffsetX(FOffsetX + ClientWidth)
            else
              if [ssShift, ssAlt] = Shift then
              begin
                if FFocusedColumn <= NoColumn then
                  NewColumn := FHeader.FColumns.GetFirstVisibleColumn
                else
                begin
                  Offset := FHeader.FColumns.GetVisibleFixedWidth;
                  NewColumn := FFocusedColumn;
                  while True do
                  begin
                    TempColumn := FHeader.FColumns.GetPreviousVisibleColumn(NewColumn);
                    NewWidth := FHeader.FColumns[NewColumn].Width;
                    if (TempColumn <= NoColumn) or
                       (Offset + NewWidth >= ClientWidth) or
                       (coFixed in FHeader.FColumns[TempColumn].FOptions) then
                      Break;
                    NewColumn := TempColumn;
                    Inc(Offset, NewWidth);
                  end;
                end;
                SetFocusedColumn(NewColumn);
              end
              else
                if ssCtrl in Shift then
                  SetOffsetY(FOffsetY + ClientHeight)
                else
                begin
                  Offset := 0;
                  
                  if FFocusedNode = nil then
                    Node := GetFirstVisible(nil, True)
                  else
                  begin
                    
                    Node := FFocusedNode;
                    while True do
                    begin
                      Temp := GetPreviousVisible(Node, True);
                      NewHeight := NodeHeight[Node];
                      if (Temp = nil) or (Offset + NewHeight >= ClientHeight) then
                        Break;
                      Node := Temp;
                      Inc(Offset, NodeHeight[Node]);
                    end;
                  end;
                  FocusedNode := Node;
                end;
          VK_NEXT:
            if Shift = [ssCtrl, ssShift] then
              SetOffsetX(FOffsetX - ClientWidth)
            else
              if [ssShift, ssAlt] = Shift then
              begin
                if FFocusedColumn <= NoColumn then
                  NewColumn := FHeader.FColumns.GetFirstVisibleColumn
                else
                begin
                  Offset := FHeader.FColumns.GetVisibleFixedWidth;
                  NewColumn := FFocusedColumn;
                  while True do
                  begin
                    TempColumn := FHeader.FColumns.GetNextVisibleColumn(NewColumn);
                    NewWidth := FHeader.FColumns[NewColumn].Width;
                    if (TempColumn <= NoColumn) or
                       (Offset + NewWidth >= ClientWidth) or
                       (coFixed in FHeader.FColumns[TempColumn].FOptions) then
                      Break;
                    NewColumn := TempColumn;
                    Inc(Offset, NewWidth);
                  end;
                end;
                SetFocusedColumn(NewColumn);
              end
              else
                if ssCtrl in Shift then
                  SetOffsetY(FOffsetY - ClientHeight)
                else
                begin
                  Offset := 0;
                  
                  if FFocusedNode = nil then
                    Node := GetLastVisible(nil, True)
                  else
                  begin
                    
                    Node := FFocusedNode;
                    while True do
                    begin
                      Temp := GetNextVisible(Node, True);
                      NewHeight := NodeHeight[Node];
                      if (Temp = nil) or (Offset + NewHeight >= ClientHeight) then
                        Break;
                      Node := Temp;
                      Inc(Offset, NewHeight);
                    end;
                  end;
                  FocusedNode := Node;
                end;
          VK_UP:
            begin
              
              if ssCtrl in Shift then
                SetOffsetY(FOffsetY + Integer(FDefaultNodeHeight))
              else
              begin
                if FFocusedNode = nil then
                  Node := GetLastVisible(nil, True)
                else
                  Node := GetPreviousVisible(FFocusedNode, True);

                if Assigned(Node) then
                begin
                  EndEditNode;
                  if HandleMultiSelect and (CompareNodePositions(LastFocused, FRangeAnchor) > 0) and
                    Assigned(FFocusedNode) then
                    RemoveFromSelection(FFocusedNode);
                  if FFocusedColumn <= NoColumn then
                    FFocusedColumn := FHeader.MainColumn;
                  FocusedNode := Node;
                end
                else
                  if Assigned(FFocusedNode) then
                    InvalidateNode(FFocusedNode);
              end;
            end;
          VK_DOWN:
            begin
              
              if ssCtrl in Shift then
                SetOffsetY(FOffsetY - Integer(FDefaultNodeHeight))
              else
              begin
                if FFocusedNode = nil then
                  Node := GetFirstVisible(nil, True)
                else
                  Node := GetNextVisible(FFocusedNode, True);

                if Assigned(Node) then
                begin
                  EndEditNode;
                  if HandleMultiSelect and (CompareNodePositions(LastFocused, FRangeAnchor) < 0) and
                    Assigned(FFocusedNode) then
                    RemoveFromSelection(FFocusedNode);
                  if FFocusedColumn <= NoColumn then
                    FFocusedColumn := FHeader.MainColumn;
                  FocusedNode := Node;
                end
                else
                  if Assigned(FFocusedNode) then
                    InvalidateNode(FFocusedNode);
              end;
            end;
          VK_LEFT:
            begin
              
              if ssCtrl in Shift then
                SetOffsetX(FOffsetX + RTLFactor * FHeader.Columns.GetScrollWidth)
              else
              begin
                
                Context := NoColumn;
                if (toExtendedFocus in FOptions.FSelectionOptions) and (toGridExtensions in FOptions.FMiscOptions) then
                begin
                  Context := FHeader.Columns.GetPreviousVisibleColumn(FFocusedColumn, True);
                  if Context > -1 then
                    FocusedColumn := Context
                end
                else
                  if Assigned(FFocusedNode) and (vsExpanded in FFocusedNode.States) and
                     (Shift = []) and (vsHasChildren in FFocusedNode.States) then
                    ToggleNode(FFocusedNode)
                  else
                  begin
                    if FFocusedNode = nil then
                      FocusedNode := GetFirstVisible(nil, True)
                    else
                    begin
                      if FFocusedNode.Parent <> FRoot then
                        Node := FFocusedNode.Parent
                      else
                        Node := nil;
                      if Assigned(Node) then
                      begin
                        if HandleMultiSelect then
                        begin
                          
                          if FFocusedNode.Index > 0 then
                            DoRangeSelect := True
                          else
                           if CompareNodePositions(Node, FRangeAnchor) > 0 then
                             RemoveFromSelection(FFocusedNode);
                        end;
                        FocusedNode := Node;
                      end;
                    end;
                  end;
              end;
            end;
          VK_RIGHT:
            begin
              
              if ssCtrl in Shift then
                SetOffsetX(FOffsetX - RTLFactor * FHeader.Columns.GetScrollWidth)
              else
              begin
                
                Context := NoColumn;
                if (toExtendedFocus in FOptions.FSelectionOptions) and (toGridExtensions in FOptions.FMiscOptions) then
                begin
                  Context := FHeader.Columns.GetNextVisibleColumn(FFocusedColumn, True);
                  if Context > -1 then
                    FocusedColumn := Context;
                end
                else
                  if Assigned(FFocusedNode) and not (vsExpanded in FFocusedNode.States) and
                     (Shift = []) and (vsHasChildren in FFocusedNode.States) then
                    ToggleNode(FFocusedNode)
                  else
                  begin
                    if FFocusedNode = nil then
                      FocusedNode := GetFirstVisible(nil, True)
                    else
                    begin
                      Node := GetFirstVisibleChild(FFocusedNode);
                      if Assigned(Node) then
                      begin
                        if HandleMultiSelect and (CompareNodePositions(Node, FRangeAnchor) < 0) then
                          RemoveFromSelection(FFocusedNode);
                        FocusedNode := Node;
                      end;
                    end;
                  end;
              end;
            end;
          VK_BACK:
            if tsIncrementalSearching in FStates then
              DoStateChange([tsIncrementalSearchPending])
            else
              if Assigned(FFocusedNode) and (FFocusedNode.Parent <> FRoot) then
                FocusedNode := FocusedNode.Parent;
          VK_TAB:
            if (toExtendedFocus in FOptions.FSelectionOptions) and FHeader.UseColumns then
            begin
              
              if ssShift in Shift then
              begin
                GetStartColumn := FHeader.FColumns.GetLastVisibleColumn;
                GetNextColumn := FHeader.FColumns.GetPreviousVisibleColumn;
                GetNextNode := GetPreviousVisible;
              end
              else
              begin
                GetStartColumn := FHeader.FColumns.GetFirstVisibleColumn;
                GetNextColumn := FHeader.FColumns.GetNextVisibleColumn;
                GetNextNode := GetNextVisible;
              end;
              
              Node := FFocusedNode;
              NewColumn := GetNextColumn(FFocusedColumn, True);
              repeat
                
                while (NewColumn > NoColumn) and not DoFocusChanging(FFocusedNode, Node, FFocusedColumn, NewColumn) do
                  NewColumn := GetNextColumn(NewColumn, True);

                if NewColumn > NoColumn then
                begin
                  
                  SetFocusedNodeAndColumn(Node, NewColumn);
                  Break;
                end;
                
                Node := GetNextNode(Node);
                NewColumn := GetStartColumn;
              until Node = nil;
            end;
        end;
        
        ForceSelection := False;
        if ClearPending and ((LastFocused <> FFocusedNode) or (FSelectionCount <> 1)) then
        begin
          ClearSelection;
          ForceSelection := True;
        end;
        
        if Shift = [] then
        begin
          FRangeAnchor := FFocusedNode;
          FLastSelectionLevel := GetNodeLevel(FFocusedNode);
        end;

        if Assigned(FFocusedNode) then
        begin
          
          if DoRangeSelect then
            ToggleSelection(LastFocused, FFocusedNode);
          
          if (LastFocused <> FFocusedNode) or ForceSelection then
            AddToSelection(FFocusedNode);
        end;
        
        if NeedInvalidate then
          Invalidate;
      end
      else
      begin
        
        GetKeyboardState(KeyState);
        
        KeyState[VK_CONTROL] := 0;
        if ToASCII(Message.CharCode, (Message.KeyData shr 16) and 7, KeyState, @Buffer, 0) > 0 then
        begin
          case Buffer[0] of
            '*':
              CharCode := VK_MULTIPLY;
            '+':
              CharCode := VK_ADD;
            '/':
              CharCode := VK_DIVIDE;
            '-':
              CharCode := VK_SUBTRACT;
          end;
        end;
        
        ToASCII(Message.CharCode, (Message.KeyData shr 16) and 7, KeyState, @Buffer, 0);

        case CharCode of
          VK_F2:
            if (Shift = []) and Assigned(FFocusedNode) and CanEdit(FFocusedNode, FFocusedColumn) then
            begin
              FEditColumn := FFocusedColumn;
              DoEdit;
            end;
          VK_ADD:
            if not (tsIncrementalSearching in FStates) then
            begin
              if ssCtrl in Shift then
                if not (toReverseFullExpandHotKey in TreeOptions.MiscOptions) and (ssShift in Shift) then
                  FullExpand
                else
                  FHeader.AutoFitColumns
              else
                if Assigned(FFocusedNode) and not (vsExpanded in FFocusedNode.States) then
                  ToggleNode(FFocusedNode);
            end
            else
              DoStateChange([tsIncrementalSearchPending]);
          VK_SUBTRACT:
            if not (tsIncrementalSearching in FStates) then
            begin
              if ssCtrl in Shift then
                if not (toReverseFullExpandHotKey in TreeOptions.MiscOptions) and (ssShift in Shift) then
                  FullCollapse
                else
                  FHeader.RestoreColumns
              else
                if Assigned(FFocusedNode) and (vsExpanded in FFocusedNode.States) then
                  ToggleNode(FFocusedNode);
            end
            else
              DoStateChange([tsIncrementalSearchPending]);
          VK_MULTIPLY:
            if not (tsIncrementalSearching in FStates) then
            begin
              if Assigned(FFocusedNode) then
                FullExpand(FFocusedNode);
            end
            else
              DoStateChange([tsIncrementalSearchPending]);
          VK_DIVIDE:
            if not (tsIncrementalSearching in FStates) then
            begin
              if Assigned(FFocusedNode) then
                FullCollapse(FFocusedNode);
            end
            else
              DoStateChange([tsIncrementalSearchPending]);
          VK_ESCAPE: 
            begin
              if IsMouseSelecting then
              begin
                DoStateChange([], [tsDrawSelecting, tsDrawSelPending]);
                Invalidate;
              end
              else
                if IsEditing then
                  CancelEditNode;
            end;
          VK_SPACE:
            if (toCheckSupport in FOptions.FMiscOptions) and Assigned(FFocusedNode) and
              (FFocusedNode.CheckType <> ctNone) then
            begin
              if (FStates * [tsKeyCheckPending, tsMouseCheckPending] = []) and
                not (vsDisabled in FFocusedNode.States) then
              begin
                with FFocusedNode^ do
                  NewCheckState := DetermineNextCheckState(CheckType, CheckState);
                if DoChecking(FFocusedNode, NewCheckState) then
                begin
                  DoStateChange([tsKeyCheckPending]);
                  FCheckNode := FFocusedNode;
                  FPendingCheckState := NewCheckState;
                  FCheckNode.CheckState := PressedState[FCheckNode.CheckState];
                  RepaintNode(FCheckNode);
                end;
              end;
            end
            else
              DoStateChange([tsIncrementalSearchPending]);
          VK_F1:
            if Assigned(FOnGetHelpContext) then
            begin
              Context := 0;
              if Assigned(FFocusedNode) then
              begin
                Node := FFocusedNode;
                
                repeat
                  FOnGetHelpContext(Self, Node, IfThen(FFocusedColumn > NoColumn, FFocusedColumn, 0), Context);
                  Node := Node.Parent;
                until (Node = FRoot) or (Context <> 0);
              end;
              
              ParentControl := Self;
              while Assigned(ParentControl) and (Context = 0) do
              begin
                Context := ParentControl.HelpContext;
                ParentControl := ParentControl.Parent;
              end;
              if Context <> 0 then
                Application.HelpContext(Context);
            end;
          VK_APPS:
            if Assigned(FFocusedNode) then
            begin
              R := GetDisplayRect(FFocusedNode, FFocusedColumn, True);
              Offset := DoGetNodeWidth(FFocusedNode, FFocusedColumn);
              if FFocusedColumn >= 0 then
              begin
                if Offset > FHeader.Columns[FFocusedColumn].Width then
                  Offset := FHeader.Columns[FFocusedColumn].Width;
              end
              else
              begin
                if Offset > ClientWidth then
                  Offset := ClientWidth;
              end;
              DoPopupMenu(FFocusedNode, FFocusedColumn, Point(R.Left + Offset div 2, (R.Top + R.Bottom) div 2));
            end;
          Ord('a'), Ord('A'):
            if ssCtrl in Shift then
              SelectAll(True)
            else
              DoStateChange([tsIncrementalSearchPending]);
        else
        begin
          
          if (Shift * [ssCtrl, ssAlt] = []) and (CharCode >= 32) then
            DoStateChange([tsIncrementalSearchPending]);
          end;
        end;
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.WMKeyUp(var Message: TWMKeyUp);

begin
  inherited;

  case Message.CharCode of
    VK_SPACE:
      if tsKeyCheckPending in FStates then
      begin
        DoStateChange([], [tskeyCheckPending]);
        if FCheckNode = FFocusedNode then
          DoCheckClick(FCheckNode, FPendingCheckState);
        InvalidateNode(FCheckNode);
        FCheckNode := nil;
      end;
     VK_TAB:
       EnsureNodeFocused(); 
  end;
end;

procedure TBaseVirtualTree.WMKillFocus(var Msg: TWMKillFocus);

var
  Form: TCustomForm;
  Control: TWinControl;
  Pos: TSmallPoint;
  Unknown: IUnknown;

begin
  inherited;
  
  Application.CancelHint;
  
  StopWheelPanning;
  
  StopTimer(ExpandTimer);
  StopTimer(EditTimer);
  StopTimer(HeaderTimer);
  StopTimer(ScrollTimer);
  StopTimer(SearchTimer);
  FSearchBuffer := '';
  FLastSearchNode := nil;

  DoStateChange([], [tsScrollPending, tsScrolling, tsEditPending, tsLeftButtonDown, tsRightButtonDown,
    tsMiddleButtonDown, tsOLEDragPending, tsVCLDragPending, tsIncrementalSearching, tsNodeHeightTrackPending,
    tsNodeHeightTracking]);

  if (FSelectionCount > 0) or not (toGhostedIfUnfocused in FOptions.FPaintOptions) then
    Invalidate
  else
    if Assigned(FFocusedNode) then
      InvalidateNode(FFocusedNode);
  
  Form := GetParentForm(Self);
  if Assigned(Form) and (Form.ActiveControl = Self) then
  begin
    Cardinal(Pos) := GetMessagePos;
    Control := FindVCLWindow(SmallPointToPoint(Pos));
    
    if Assigned(Control) and Control.GetInterface(IOleClientSite, Unknown) then
      Form.ActiveControl := nil;
    
  end;
end;

procedure TBaseVirtualTree.WMLButtonDblClk(var Message: TWMLButtonDblClk);

var
  HitInfo: THitInfo;

begin
  DoStateChange([tsLeftDblClick]);
  inherited;
  
  GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);
  HandleMouseDblClick(Message, HitInfo);
  DoStateChange([], [tsLeftDblClick]);
end;

procedure TBaseVirtualTree.WMLButtonDown(var Message: TWMLButtonDown);

var
  HitInfo: THitInfo;

begin
  DoStateChange([tsLeftButtonDown]);
  inherited;
  
  GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);
  HandleMouseDown(Message, HitInfo);
end;

procedure TBaseVirtualTree.WMLButtonUp(var Message: TWMLButtonUp);

var
  HitInfo: THitInfo;

begin
  DoStateChange([], [tsLeftButtonDown, tsNodeHeightTracking, tsNodeHeightTrackPending]);
  
  GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);
  HandleMouseUp(Message, HitInfo);

  inherited;
end;

procedure TBaseVirtualTree.WMMButtonDblClk(var Message: TWMMButtonDblClk);

var
  HitInfo: THitInfo;

begin
  DoStateChange([tsMiddleDblClick]);
  inherited;
  
  if toMiddleClickSelect in FOptions.FSelectionOptions then
  begin
    GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);
    HandleMouseDblClick(Message, HitInfo);
  end;
  DoStateChange([], [tsMiddleDblClick]);
end;

procedure TBaseVirtualTree.WMMButtonDown(var Message: TWMMButtonDown);

var
  HitInfo: THitInfo;

begin
  DoStateChange([tsMiddleButtonDown]);

  if FHeader.FStates = [] then
  begin
    inherited;
    
    if (toWheelPanning in FOptions.FMiscOptions) and ([tsWheelScrolling, tsWheelPanning] * FStates = []) and
      ((Integer(FRangeX) > ClientWidth) or (Integer(FRangeY) > ClientHeight)) then
    begin
      FLastClickPos := SmallPointToPoint(Message.Pos);
      StartWheelPanning(FLastClickPos);
    end
    else
    begin
      StopWheelPanning;
      
      if toMiddleClickSelect in FOptions.FSelectionOptions then
      begin
        GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);
        HandleMouseDown(Message, HitInfo);
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.WMMButtonUp(var Message: TWMMButtonUp);

var
  HitInfo: THitInfo;

begin
  DoStateChange([], [tsMiddleButtonDown]);
  
  if [tsWheelPanning, tsWheelScrolling] * FStates <> [] then
  begin
    if tsWheelScrolling in FStates then
      DoStateChange([], [tsWheelPanning])
    else
      StopWheelPanning;
  end
  else
    if FHeader.FStates = [] then
    begin
      inherited;
      
      if toMiddleClickSelect in FOptions.FSelectionOptions then
      begin
        GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);
        HandleMouseUp(Message, HitInfo);
      end;
    end;
end;

procedure TBaseVirtualTree.WMNCCalcSize(var Message: TWMNCCalcSize);

begin
  inherited;

  with FHeader do
    if hoVisible in FHeader.FOptions then
      with Message.CalcSize_Params^ do
        Inc(rgrc[0].Top, FHeight);
end;

procedure TBaseVirtualTree.WMNCDestroy(var Message: TWMNCDestroy);

begin
  InterruptValidation;

  StopTimer(ChangeTimer);
  StopTimer(StructureChangeTimer);

  if not (csDesigning in ComponentState) and (toAcceptOLEDrop in FOptions.FMiscOptions) then
    RevokeDragDrop(Handle);
  
  DeleteObject(FDottedBrush);
  FDottedBrush := 0;
  if tsInAnimation in FStates then
    FHintWindowDestroyed := True; 

  inherited;
end;

procedure TBaseVirtualTree.WMNCHitTest(var Message: TWMNCHitTest);

begin
  inherited;
  if not (csDesigning in ComponentState) and (hoVisible in FHeader.FOptions) and
    FHeader.InHeader(ScreenToClient(SmallPointToPoint(Message.Pos))) then
    Message.Result := HTBORDER;
end;

procedure TBaseVirtualTree.WMNCPaint(var Message: TRealWMNCPaint);

var
  DC: HDC;
  R: TRect;
  Flags: DWORD;
  ExStyle: Integer;
  TempRgn: HRGN;
  BorderWidth,
  BorderHeight: Integer;

begin
  if tsUseThemes in FStates then
  begin
    
    ExStyle := GetWindowLong(Handle, GWL_EXSTYLE);
    if (ExStyle and WS_EX_CLIENTEDGE) <> 0 then
    begin
      GetWindowRect(Handle, R);
      
      BorderWidth := GetSystemMetrics(SM_CXEDGE);
      BorderHeight := GetSystemMetrics(SM_CYEDGE);
      InflateRect(R, -BorderWidth, -BorderHeight);
      TempRgn := CreateRectRgnIndirect(R);
      
      if Message.Rgn <> 1 then
        CombineRgn(TempRgn, Message.Rgn, TempRgn, RGN_AND);
      DefWindowProc(Handle, Message.Msg, WPARAM(TempRgn), 0);
      DeleteObject(TempRgn);
    end
    else
      DefaultHandler(Message);
  end
  else
    DefaultHandler(Message);

  Flags := DCX_CACHE or DCX_CLIPSIBLINGS or DCX_WINDOW or DCX_VALIDATE;

  if (Message.Rgn = 1) then
    DC := GetDCEx(Handle, 0, Flags)
  else
    DC := GetDCEx(Handle, Message.Rgn, Flags or DCX_INTERSECTRGN);

  if DC <> 0 then
  begin
    if hoVisible in FHeader.FOptions then
    begin
      R := FHeaderRect;
      FHeader.FColumns.PaintHeader(DC, R, -FEffectiveOffsetX);
    end;
    OriginalWMNCPaint(DC);
    ReleaseDC(Handle, DC);
  end;
    if tsUseThemes in FStates then
      StyleServices.PaintBorder(Self, False);
end;

procedure TBaseVirtualTree.WMPaint(var Message: TWMPaint);

begin
  if tsVCLDragging in FStates then
    ImageList_DragShowNolock(False);
  if csPaintCopy in ControlState then
    FUpdateRect := ClientRect
  else
    GetUpdateRect(Handle, FUpdateRect, True);

  inherited;

  if tsVCLDragging in FStates then
    ImageList_DragShowNolock(True);
end;

procedure TBaseVirtualTree.WMPaste(var Message: TWMPaste);

begin
  PasteFromClipboard;
end;

procedure TBaseVirtualTree.WMPrint(var Message: TWMPrint);

begin
  
  if ((Message.Flags and PRF_CHECKVISIBLE) = 0) or IsWindowVisible(Handle) then
    Header.Columns.PaintHeader(Message.DC, FHeaderRect, -FEffectiveOffsetX);

  inherited;
end;

procedure TBaseVirtualTree.WMPrintClient(var Message: TWMPrintClient);

var
  Window: TRect;
  Target: TPoint;
  Canvas: TCanvas;

begin
  
  if ((Message.Flags and PRF_CHECKVISIBLE) = 0) or IsWindowVisible(Handle) then
  begin
    
    Window := ClientRect;
    Target := Window.TopLeft;
    
    OffsetRect(Window, FEffectiveOffsetX, -FOffsetY);

    Canvas := TCanvas.Create;
    try
      Canvas.Handle := Message.DC;
      PaintTree(Canvas, Window, Target, [poBackground, poDrawFocusRect, poDrawDropMark, poDrawSelection, poGridLines]);
    finally
      Canvas.Handle := 0;
      Canvas.Free;
    end;
  end;
end;

procedure TBaseVirtualTree.WMRButtonDblClk(var Message: TWMRButtonDblClk);

var
  HitInfo: THitInfo;

begin
  DoStateChange([tsRightDblClick]);
  inherited;
  
  if toMiddleClickSelect in FOptions.FSelectionOptions then
  begin
    GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);
    HandleMouseDblClick(Message, HitInfo);
  end;
  DoStateChange([], [tsRightDblClick]);
end;

procedure TBaseVirtualTree.WMRButtonDown(var Message: TWMRButtonDown);

var
  HitInfo: THitInfo;

begin
  DoStateChange([tsRightButtonDown]);

  if FHeader.FStates = [] then
  begin
    inherited;
    
    if toRightClickSelect in FOptions.FSelectionOptions then
    begin
      GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);
      HandleMouseDown(Message, HitInfo);
    end;
  end;
end;

procedure TBaseVirtualTree.WMRButtonUp(var Message: TWMRButtonUp);

var
  HitInfo: THitInfo;

begin
  DoStateChange([], [tsPopupMenuShown, tsRightButtonDown]);

  if FHeader.FStates = [] then
  begin
    Application.CancelHint;

    if IsMouseSelecting and Assigned(PopupMenu) then
    begin
      
      DoStateChange([], [tsDrawSelecting, tsDrawSelPending]);
      Invalidate;
    end;

    inherited;
    
    GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);

    if toRightClickSelect in FOptions.FSelectionOptions then
      HandleMouseUp(Message, HitInfo);

    if not Assigned(PopupMenu) then
      DoPopupMenu(HitInfo.HitNode, HitInfo.HitColumn, Point(Message.XPos, Message.YPos));
  end;
end;

procedure TBaseVirtualTree.WMSetCursor(var Message: TWMSetCursor);

var
  NewCursor: TCursor;
  HitInfo: THitInfo;
  P: TPoint;
  Node: PVirtualNode;

begin
  with Message do
  begin
    if (CursorWnd = Handle) and not (csDesigning in ComponentState) and
      ([tsWheelPanning, tsWheelScrolling] * FStates = []) then
    begin
      if not FHeader.HandleMessage(TMessage(Message)) then
      begin
        
        if Screen.Cursor = crDefault then
        begin
          NewCursor := crDefault;
          if (toNodeHeightResize in FOptions.FMiscOptions) then
          begin
            GetCursorPos(P);
            P := ScreenToClient(P);
            GetHitTestInfoAt(P.X, P.Y, True, HitInfo);
            if (hiOnItem in HitInfo.HitPositions) and
               ([hiUpperSplitter, hiLowerSplitter] * HitInfo.HitPositions <> []) then
            begin
              if hiUpperSplitter in HitInfo.HitPositions then
                Node := GetPreviousVisible(HitInfo.HitNode, True)
              else
                Node := HitInfo.HitNode;

              if CanSplitterResizeNode(P, Node, HitInfo.HitColumn) then
                NewCursor := crVertSplit;
            end;
          end;

          if (NewCursor = crDefault) then
            if (toHotTrack in FOptions.PaintOptions) and Assigned(FCurrentHotNode) and (FHotCursor <> crDefault) then
              NewCursor := FHotCursor
            else
              NewCursor := Cursor;

          DoGetCursor(NewCursor);
          Windows.SetCursor(Screen.Cursors[NewCursor]);
          Message.Result := 1;
        end
        else
          inherited;
      end;
    end
    else
      inherited;
  end;
end;

procedure TBaseVirtualTree.WMSetFocus(var Msg: TWMSetFocus);

begin
  inherited;
  if (FSelectionCount > 0) or not (toGhostedIfUnfocused in FOptions.FPaintOptions) then
    Invalidate;
end;

procedure TBaseVirtualTree.WMSize(var Message: TWMSize);

begin
  inherited;
  
  if HandleAllocated and ([tsSizing, tsWindowCreating] * FStates = []) and (ClientHeight > 0) then
  try
    DoStateChange([tsSizing]);
    
    FHeader.RescaleHeader;
    FHeader.UpdateSpringColumns;
    UpdateScrollBars(True);

    if (tsEditing in FStates) and not FHeader.UseColumns then
      UpdateEditBounds;
  finally
    DoStateChange([], [tsSizing]);
  end;
end;

procedure TBaseVirtualTree.WMThemeChanged(var Message: TMessage);

begin
  inherited;

  if StyleServices.Enabled and (toThemeAware in TreeOptions.PaintOptions) then
    DoStateChange([tsUseThemes])
  else
    DoStateChange([], [tsUseThemes]);
  
  if not FChangingTheme then
    SetTimer(Handle, ThemeChangedTimer, ThemeChangedTimerDelay, nil);
  FChangingTheme := False;
end;

procedure TBaseVirtualTree.WMTimer(var Message: TWMTimer);

begin
  with Message do
  begin
    case TimerID of
      ExpandTimer:
        DoDragExpand;
      EditTimer:
        DoEdit;
      ScrollTimer:
        begin
          if tsScrollPending in FStates then
          begin
            Application.CancelHint;
            
            SetTimer(Handle, ScrollTimer, FAutoScrollInterval, nil);
            DoStateChange([tsScrolling], [tsScrollPending]);
          end;
          DoTimerScroll;
        end;
      ChangeTimer:
        DoChange(FLastChangedNode);
      StructureChangeTimer:
        DoStructureChange(FLastStructureChangeNode, FLastStructureChangeReason);
      SearchTimer:
        begin
          
          DoStateChange([], [tsIncrementalSearching]);
          StopTimer(SearchTimer);
          FSearchBuffer := '';
          FLastSearchNode := nil;
        end;
      ThemeChangedTimer:
        begin
          StopTimer(ThemeChangedTimer);
          RecreateWnd;
        end;
    end;
  end;
end;

procedure TBaseVirtualTree.WMVScroll(var Message: TWMVScroll);

  function GetRealScrollPosition: Integer;

  var
    SI: TScrollInfo;
    Code: Integer;

  begin
    SI.cbSize := SizeOf(TScrollInfo);
    SI.fMask := SIF_TRACKPOS;
    Code := SB_VERT;
    GetScrollInfo(Handle, Code, SI);
    Result := SI.nTrackPos;
  end;

begin
  case Message.ScrollCode of
    SB_BOTTOM:
      SetOffsetY(-Integer(FRoot.TotalHeight));
    SB_ENDSCROLL:
      begin
        DoStateChange([], [tsThumbTracking]);
        
        UpdateScrollBars(True);
        
        RedrawWindow(Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_NOERASE or RDW_NOCHILDREN);
      end;
    SB_LINEUP:
      SetOffsetY(FOffsetY + FScrollBarOptions.FIncrementY);
    SB_LINEDOWN:
      SetOffsetY(FOffsetY - FScrollBarOptions.FIncrementY);
    SB_PAGEUP:
      SetOffsetY(FOffsetY + ClientHeight);
    SB_PAGEDOWN:
      SetOffsetY(FOffsetY - ClientHeight);

    SB_THUMBPOSITION,
    SB_THUMBTRACK:
      begin
        DoStateChange([tsThumbTracking]);
        SetOffsetY(-GetRealScrollPosition);
      end;
    SB_TOP:
      SetOffsetY(0);
  end;
  Message.Result := 0;
end;

procedure TBaseVirtualTree.AddToSelection(Node: PVirtualNode);

var
  Changed: Boolean;

begin
  if not FSelectionLocked then
  begin
    Assert(Assigned(Node), 'Node must not be nil!');
    FSingletonNodeArray[0] := Node;
    Changed := InternalAddToSelection(FSingletonNodeArray, 1, False);
    if Changed then
    begin
      InvalidateNode(Node);
      Change(Node);
    end;
  end;
end;

procedure TBaseVirtualTree.AddToSelection(const NewItems: TNodeArray; NewLength: Integer; ForceInsert: Boolean = False);

var
  Changed: Boolean;

begin
  Changed := InternalAddToSelection(NewItems, NewLength, ForceInsert);
  if Changed then
  begin
    if NewLength = 1 then
    begin
      InvalidateNode(NewItems[0]);
      Change(NewItems[0]);
    end
    else
    begin
      Invalidate;
      Change(nil);
    end;
  end;
end;

procedure TBaseVirtualTree.AdjustImageBorder(Images: TCustomImageList; BidiMode: TBidiMode; VAlign: Integer; var R: TRect;
  var ImageInfo: TVTImageInfo);

begin
  if BidiMode = bdLeftToRight then
  begin
    ImageInfo.XPos := R.Left;
    Inc(R.Left, Images.Width + 2);
  end
  else
  begin
    ImageInfo.XPos := R.Right - Images.Width;
    Dec(R.Right, Images.Width + 2);
  end;
  ImageInfo.YPos := R.Top + VAlign - Images.Height div 2;
end;

procedure TBaseVirtualTree.AdjustPaintCellRect(var PaintInfo: TVTPaintInfo; var NextNonEmpty: TColumnIndex);

begin
  
  NextNonEmpty := FHeader.FColumns.GetNextVisibleColumn(PaintInfo.Column);
end;

procedure TBaseVirtualTree.AdjustPanningCursor(X, Y: Integer);

var
  Name: string;
  NewCursor: HCURSOR;
  ScrollHorizontal,
  ScrollVertical: Boolean;

begin
  ScrollHorizontal := Integer(FRangeX) > ClientWidth;
  ScrollVertical := Integer(FRangeY) > ClientHeight;

  if (Abs(X - FLastClickPos.X) < 8) and (Abs(Y - FLastClickPos.Y) < 8) then
  begin
    
    if ScrollHorizontal then
    begin
      if ScrollVertical then
        Name := 'VT_MOVEALL'
      else
        Name := 'VT_MOVEEW'
    end
    else
      Name := 'VT_MOVENS';
  end
  else
  begin
    
    if ScrollVertical and ScrollHorizontal then
    begin
      
      if X - FlastClickPos.X < -8 then
      begin
        
        if Y - FLastClickPos.Y < -8 then
          Name := 'VT_MOVENW'
        else
          if Y - FLastClickPos.Y > 8 then
            Name := 'VT_MOVESW'
          else
            Name := 'VT_MOVEW';
      end
      else
        if X - FLastClickPos.X > 8 then
        begin
          
          if Y - FLastClickPos.Y < -8 then
            Name := 'VT_MOVENE'
          else
            if Y - FLastClickPos.Y > 8 then
              Name := 'VT_MOVESE'
            else
              Name := 'VT_MOVEE';
        end
        else
        begin
          
          if Y < FLastClickPos.Y then
            Name := 'VT_MOVEN'
          else
            Name := 'VT_MOVES';
        end;
    end
    else
      if ScrollHorizontal then
      begin
        
        if X < FlastClickPos.X then
          Name := 'VT_MOVEW'
        else
          Name := 'VT_MOVEE';
      end
      else
      begin
        
        if Y < FlastClickPos.Y then
          Name := 'VT_MOVEN'
        else
          Name := 'VT_MOVES';
      end;
  end;
  
  NewCursor := LoadCursor(HInstance, PChar(Name));
  if FPanningCursor <> NewCursor then
  begin
    DeleteObject(FPanningCursor);
    FPanningCursor := NewCursor;
    Windows.SetCursor(FPanningCursor);
  end
  else
    DeleteObject(NewCursor);
end;

procedure TBaseVirtualTree.AdviseChangeEvent(StructureChange: Boolean; Node: PVirtualNode; Reason: TChangeReason);

begin
  if StructureChange then
  begin
    if tsStructureChangePending in FStates then
      StopTimer(StructureChangeTimer)
    else
      DoStateChange([tsStructureChangePending]);

    FLastStructureChangeNode := Node;
    if FLastStructureChangeReason = crIgnore then
      FLastStructureChangeReason := Reason
    else
      if Reason <> crIgnore then
        FLastStructureChangeReason := crAccumulated;
  end
  else
  begin
    if tsChangePending in FStates then
      StopTimer(ChangeTimer)
    else
      DoStateChange([tsChangePending]);

    FLastChangedNode := Node;
  end;
end;

function TBaseVirtualTree.AllocateInternalDataArea(Size: Cardinal): Cardinal;

begin
  Assert((FRoot = nil) or (FRoot.ChildCount = 0), 'Internal data allocation must be done before any node is created.');

  Result := TreeNodeSize + FTotalInternalDataSize;
  Inc(FTotalInternalDataSize, (Size + (SizeOf(Pointer) - 1)) and not (SizeOf(Pointer) - 1));
  InitRootNode(Result);
end;

procedure TBaseVirtualTree.Animate(Steps, Duration: Cardinal; Callback: TVTAnimationCallback; Data: Pointer);

var
  StepSize,
  RemainingTime,
  RemainingSteps,
  NextTimeStep,
  CurrentStep,
  StartTime,
  CurrentTime: Cardinal;

begin
  if not (tsInAnimation in FStates) and (Duration > 0) then
  begin
    DoStateChange([tsInAnimation]);
    try
      RemainingTime := Duration;
      RemainingSteps := Steps;
      
      StepSize := Round(Max(1, RemainingSteps / Duration));
      RemainingSteps := RemainingSteps div StepSize;
      CurrentStep := 0;

      while (RemainingSteps > 0) and (RemainingTime > 0) and not Application.Terminated do
      begin
        StartTime := timeGetTime;
        NextTimeStep := StartTime + RemainingTime div RemainingSteps;
        if not Callback(CurrentStep, StepSize, Data) then
          Break;
        
        CurrentTime := timeGetTime;
        
        while CurrentTime < NextTimeStep do
          CurrentTime := timeGetTime;
        
        if RemainingTime >= CurrentTime - StartTime then
        begin
          Dec(RemainingTime, CurrentTime - StartTime);
          Dec(RemainingSteps);
        end
        else
        begin
          RemainingTime := 0;
          RemainingSteps := 0;
        end;
        
        if (RemainingSteps > 0) and ((RemainingTime div RemainingSteps) < 1) then
        begin
          repeat
            Inc(StepSize);
            RemainingSteps := RemainingTime div StepSize;
          until (RemainingSteps <= 0) or ((RemainingTime div RemainingSteps) >= 1);
        end;
        CurrentStep := Cardinal(Steps) - RemainingSteps;
      end;

      if not Application.Terminated then
        Callback(0, 0, Data);
    finally
      DoStateChange([], [tsCancelHintAnimation, tsInAnimation]);
    end;
  end;
end;

procedure TBaseVirtualTree.StartOperation(OperationKind: TVTOperationKind);

begin
  Inc(FOperationCount);
  DoStartOperation(OperationKind);
  if FOperationCount = 1 then
    FOperationCanceled := False;
end;

function TBaseVirtualTree.CalculateSelectionRect(X, Y: Integer): Boolean;

var
  MaxValue: Integer;

begin
  if tsDrawSelecting in FStates then
    FLastSelRect := FNewSelRect;
  FNewSelRect.BottomRight := Point(X + FEffectiveOffsetX, Y - FOffsetY);
  if FNewSelRect.Right < 0 then
    FNewSelRect.Right := 0;
  if FNewSelRect.Bottom < 0 then
    FNewSelRect.Bottom := 0;
  MaxValue := ClientWidth;
  if FRangeX > Cardinal(MaxValue) then
    MaxValue := FRangeX;
  if FNewSelRect.Right > MaxValue then
    FNewSelRect.Right := MaxValue;
  MaxValue := ClientHeight;
  if FRangeY > Cardinal(MaxValue) then
    MaxValue := FRangeY;
  if FNewSelRect.Bottom > MaxValue then
    FNewSelRect.Bottom := MaxValue;

  Result := not CompareMem(@FLastSelRect, @FNewSelRect, SizeOf(FNewSelRect));
end;

function TBaseVirtualTree.CanAutoScroll: Boolean;

var
  IsDropTarget: Boolean;
  IsDrawSelecting: Boolean;
  IsWheelPanning: Boolean;

begin
  
  IsDropTarget := Assigned(FDragManager) and DragManager.IsDropTarget;
  IsDrawSelecting := [tsDrawSelPending, tsDrawSelecting] * FStates <> [];
  IsWheelPanning := [tsWheelPanning, tsWheelScrolling] * FStates <> [];
  Result := ((toAutoScroll in FOptions.FAutoOptions) or IsWheelPanning) and
    (FHeader.FStates = []) and (IsDrawSelecting or IsDropTarget or (tsVCLDragging in FStates) or IsWheelPanning);
end;

function TBaseVirtualTree.CanShowDragImage: Boolean;

begin
  Result := FDragImageKind <> diNoImage;
end;

function TBaseVirtualTree.CanSplitterResizeNode(P: TPoint; Node: PVirtualNode; Column: TColumnIndex): Boolean;

begin
  Result := (toNodeHeightResize in FOptions.FMiscOptions) and Assigned(Node) and (Node <> FRoot) and
            (Column > NoColumn) and (coFixed in FHeader.FColumns[Column].FOptions);
  DoCanSplitterResizeNode(P, Node, Column, Result);
end;

procedure TBaseVirtualTree.Change(Node: PVirtualNode);

begin
  AdviseChangeEvent(False, Node, crIgnore);

  if FUpdateCount = 0 then
  begin
    if (FChangeDelay > 0) and not (tsSynchMode in FStates) then
      SetTimer(Handle, ChangeTimer, FChangeDelay, nil)
    else
      DoChange(Node);
  end;
end;

procedure TBaseVirtualTree.ChangeScale(M, D: Integer);

begin
  inherited;

  if (M <> D) and (toAutoChangeScale in FOptions.FAutoOptions) then
  begin
    SetDefaultNodeHeight(MulDiv(FDefaultNodeHeight, M, D));
    FHeader.ChangeScale(M, D);
  end;
end;

function TBaseVirtualTree.CheckParentCheckState(Node: PVirtualNode; NewCheckState: TCheckState): Boolean;

var
  CheckCount,
  BoxCount: Cardinal;
  PartialCheck: Boolean;
  Run: PVirtualNode;

begin
  CheckCount := 0;
  BoxCount := 0;
  PartialCheck := False;
  Run := Node.Parent.FirstChild;
  while Assigned(Run) do
  begin
    if Run = Node then
    begin
      
      if Run.CheckType in [ctCheckBox, ctTriStateCheckBox] then
      begin
        Inc(BoxCount);
        if NewCheckState in [csCheckedNormal, csCheckedPressed] then
          Inc(CheckCount);
        PartialCheck := PartialCheck or (NewCheckState = csMixedNormal);
      end;
    end
    else
      if Run.CheckType in [ctCheckBox, ctTriStateCheckBox] then
      begin
        Inc(BoxCount);
        if Run.CheckState in [csCheckedNormal, csCheckedPressed] then
          Inc(CheckCount);
        PartialCheck := PartialCheck or (Run.CheckState = csMixedNormal);
      end;
    Run := Run.NextSibling;
  end;

  if (CheckCount = 0) and not PartialCheck then
    NewCheckState := csUncheckedNormal
  else
    if CheckCount < BoxCount then
      NewCheckState := csMixedNormal
    else
      NewCheckState := csCheckedNormal;

  Node := Node.Parent;
  Result := DoChecking(Node, NewCheckState);
  if Result then
  begin
    DoCheckClick(Node, NewCheckState);
    
  end;
end;

procedure TBaseVirtualTree.ClearTempCache;

begin
  FTempNodeCache := nil;
  FTempNodeCount := 0;
end;

function TBaseVirtualTree.ColumnIsEmpty(Node: PVirtualNode; Column: TColumnIndex): Boolean;

begin
  Result := True;
  if Assigned(FOnGetCellIsEmpty) then
    FOnGetCellIsEmpty(Self, Node, Column, Result);
end;

function TBaseVirtualTree.ComputeRTLOffset(ExcludeScrollbar: Boolean): Integer;

var
  HeaderWidth: Integer;
  ScrollbarVisible: Boolean;
begin
  ScrollbarVisible := (Integer(FRangeY) > ClientHeight) and (ScrollbarOptions.Scrollbars in [ssVertical, ssBoth]);
  if ScrollbarVisible then
    Result := GetSystemMetrics(SM_CXVSCROLL)
  else
    Result := 0;
  
  HeaderWidth := FHeaderRect.Right - FHeaderRect.Left;
  if Integer(FRangeX) + Result <= HeaderWidth then
    Result := HeaderWidth - Integer(FRangeX);

  if ScrollbarVisible and ExcludeScrollbar then
    Dec(Result, GetSystemMetrics(SM_CXVSCROLL));
end;

function TBaseVirtualTree.CountLevelDifference(Node1, Node2: PVirtualNode): Integer;

var
  Level1, Level2: Integer;

begin
  Assert(Assigned(Node1) and Assigned(Node2), 'Both nodes must be Assigned.');

  Level1 := 0;
  while Node1.Parent <> FRoot do
  begin
    Inc(Level1);
    Node1 := Node1.Parent;
  end;

  Level2 := 0;
  while Node2.Parent <> FRoot do
  begin
    Inc(Level2);
    Node2 := Node2.Parent;
  end;

  Result := Level2 - Level1;
end;

function TBaseVirtualTree.CountVisibleChildren(Node: PVirtualNode): Cardinal;

begin
  Result := 0;
  
  if vsExpanded in Node.States then
  begin
    
    Node := Node.FirstChild;
    while Assigned(Node) do
    begin
      if vsVisible in Node.States then
        Inc(Result, CountVisibleChildren(Node) + Cardinal(IfThen(IsEffectivelyVisible[Node], 1)));
      Node := Node.NextSibling;
    end;
  end;
end;

procedure TBaseVirtualTree.CreateParams(var Params: TCreateParams);

const
  ScrollBar: array[TScrollStyle] of Cardinal = (0, WS_HSCROLL, WS_VSCROLL, WS_HSCROLL or WS_VSCROLL);

begin
  inherited CreateParams(Params);

  with Params do
  begin
    Style := Style or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or ScrollBar[ScrollBarOptions.FScrollBars];
    if toFullRepaintOnResize in FOptions.FMiscOptions then
      WindowClass.style := WindowClass.style or CS_HREDRAW or CS_VREDRAW
    else
      WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
    if FBorderStyle = bsSingle then
    begin
      if Ctl3D then
      begin
        ExStyle := ExStyle or WS_EX_CLIENTEDGE;
        Style := Style and not WS_BORDER;
      end
      else
        Style := Style or WS_BORDER;
    end
    else
      Style := Style and not WS_BORDER;

    AddBiDiModeExStyle(ExStyle);
  end;
end;

procedure TBaseVirtualTree.CreateWnd;

begin
  DoStateChange([tsWindowCreating]);
  inherited;
  DoStateChange([], [tsWindowCreating]);

  if (StyleServices.Enabled and (toThemeAware in TreeOptions.PaintOptions)) or VclStyleEnabled then
  begin
    DoStateChange([tsUseThemes]);
    if not VclStyleEnabled then
      if (toUseExplorerTheme in FOptions.FPaintOptions) and IsWinVistaOrAbove then
      begin
        DoStateChange([tsUseExplorerTheme]);
         SetWindowTheme('explorer');
      end
      else
        DoStateChange([], [tsUseExplorerTheme]);
  end
  else
    DoStateChange([], [tsUseThemes, tsUseExplorerTheme]);
  
  if hsNeedScaling in FHeader.FStates then
    FHeader.RescaleHeader;
  if hoAutoResize in FHeader.FOptions then
    FHeader.FColumns.AdjustAutoSize(InvalidColumn);

  PrepareBitmaps(True, True);
  
  if not (csDesigning in ComponentState) and (toAcceptOLEDrop in FOptions.FMiscOptions) then
    RegisterDragDrop(Handle, DragManager as IDropTarget);

  UpdateScrollBars(True);
  UpdateHeaderRect;
end;

procedure TBaseVirtualTree.DefineProperties(Filer: TFiler);

var
  StoreIt: Boolean;

begin
  inherited;
  
  if FHeader.CanWriteColumns then
  begin
    
    StoreIt := Filer.Ancestor = nil;
    
    if not StoreIt then
      StoreIt := not FHeader.Columns.Equals(TBaseVirtualTree(Filer.Ancestor).FHeader.Columns);
  end
  else
    StoreIt := False;

  Filer.DefineProperty('Columns', FHeader.ReadColumns, FHeader.WriteColumns, StoreIt);
  Filer.DefineProperty('Options', ReadOldOptions, nil, False);
end;

function TBaseVirtualTree.DetermineDropMode(const P: TPoint; var HitInfo: THitInfo; var NodeRect: TRect): TDropMode;

var
  ImageHit: Boolean;
  LabelHit: Boolean;
  ItemHit: Boolean;

begin
  ImageHit := HitInfo.HitPositions * [hiOnNormalIcon, hiOnStateIcon] <> [];
  LabelHit := hiOnItemLabel in HitInfo.HitPositions;
  ItemHit := ((hiOnItem in HitInfo.HitPositions) and
             ((toFullRowDrag in FOptions.FMiscOptions) or (toFullRowSelect in FOptions.FSelectionOptions)));
  
  if (toReportMode in FOptions.FMiscOptions) and not (ItemHit or ((LabelHit or ImageHit) and
    (HitInfo.HitColumn = FHeader.MainColumn))) then
    HitInfo.HitNode := nil;

  if Assigned(HitInfo.HitNode) then
  begin
    if LabelHit or ImageHit or not (toShowDropmark in FOptions.FPaintOptions) then
      Result := dmOnNode
    else
      if ((NodeRect.Top + NodeRect.Bottom) div 2) > P.Y then
        Result := dmAbove
      else
        Result := dmBelow;
  end
  else
    Result := dmNowhere;
end;

procedure TBaseVirtualTree.DetermineHiddenChildrenFlag(Node: PVirtualNode);

var
  Run: PVirtualNode;

begin
  if Node.ChildCount = 0 then
  begin
    if vsHasChildren in Node.States then
      Exclude(Node.States, vsAllChildrenHidden)
    else
      Include(Node.States, vsAllChildrenHidden);
  end
  else
  begin
    
    Run := Node.FirstChild;
    while Assigned(Run) and not IsEffectivelyVisible[Run] do
      Run := Run.NextSibling;
    if Assigned(Run) then
      Exclude(Node.States, vsAllChildrenHidden)
    else
      Include(Node.States, vsAllChildrenHidden);
  end;
end;

procedure TBaseVirtualTree.DetermineHiddenChildrenFlagAllNodes;

var
  Run: PVirtualNode;

begin
  Run := GetFirstNoInit(False);
  while Assigned(Run) do
  begin
    DetermineHiddenChildrenFlag(Run);
    Run := GetNextNoInit(Run);
  end;
end;

procedure TBaseVirtualTree.DetermineHitPositionLTR(var HitInfo: THitInfo; Offset, Right: Integer;
  Alignment: TAlignment);

var
  MainColumnHit: Boolean;
  Run: PVirtualNode;
  Indent,
  TextWidth,
  ImageOffset: Integer;

begin
  MainColumnHit := HitInfo.HitColumn = FHeader.MainColumn;
  Indent := 0;
  
  if MainColumnHit then
  begin
    if toFixedIndent in FOptions.FPaintOptions then
      Indent := FIndent
    else
    begin
      Run := HitInfo.HitNode;
      while (Run.Parent <> FRoot) do
      begin
        Inc(Indent, FIndent);
      Run := Run.Parent;
      end;
      if toShowRoot in FOptions.FPaintOptions then
        Inc(Indent, FIndent);
    end;
  end;

  if (MainColumnHit and (Offset < (Indent + Margin))) then
  begin
    
    if (toShowButtons in FOptions.FPaintOptions) and (vsHasChildren in HitInfo.HitNode.States) then
    begin
      
      if Offset >= Indent - Integer(FIndent) then
        Include(HitInfo.HitPositions, hiOnItemButton);
      if Offset >= Indent - FPlusBM.Width then
        Include(HitInfo.HitPositions, hiOnItemButtonExact);
    end;
    
    if HitInfo.HitPositions = [] then
      Include(HitInfo.HitPositions, hiOnItemIndent);
  end
  else
  begin
    
    if MainColumnHit or not (toReportMode in FOptions.FMiscOptions) then
    begin
      ImageOffset := Indent +  FMargin;
      
      if MainColumnHit and (toCheckSupport in FOptions.FMiscOptions) and Assigned(FCheckImages) and
        (HitInfo.HitNode.CheckType <> ctNone) then
        Inc(ImageOffset, FCheckImages.Width + 2);

      if MainColumnHit and (Offset < ImageOffset) then
      begin
        HitInfo.HitPositions := [hiOnItem];
        if (HitInfo.HitNode.CheckType <> ctNone) then
          Include(HitInfo.HitPositions, hiOnItemCheckBox);
      end
      else
      begin
        if Assigned(FStateImages) and HasImage(HitInfo.HitNode, ikState, HitInfo.HitColumn) then
          Inc(ImageOffset, FStateImages.Width + 2);
        if Offset < ImageOffset then
          Include(HitInfo.HitPositions, hiOnStateIcon)
        else
        begin
          if Assigned(FImages) and HasImage(HitInfo.HitNode, ikNormal, HitInfo.HitColumn) then
            Inc(ImageOffset, GetNodeImageSize(HitInfo.HitNode).cx + 2);
          if Offset < ImageOffset then
            Include(HitInfo.HitPositions, hiOnNormalIcon)
          else
          begin
            
            TextWidth := DoGetNodeWidth(HitInfo.HitNode, HitInfo.HitColumn);
            
            if TextWidth > Right - ImageOffset then
              Include(HitInfo.HitPositions, hiOnItemLabel)
            else
            begin
              case Alignment of
                taCenter:
                  begin
                    Indent := (ImageOffset + Right - TextWidth) div 2;
                    if Offset < Indent then
                      Include(HitInfo.HitPositions, hiOnItemLeft)
                    else
                      if Offset < Indent + TextWidth then
                        Include(HitInfo.HitPositions, hiOnItemLabel)
                      else
                        Include(HitInfo.HitPositions, hiOnItemRight)
                  end;
                taRightJustify:
                  begin
                    Indent := Right - TextWidth;
                    if Offset < Indent then
                      Include(HitInfo.HitPositions, hiOnItemLeft)
                    else
                      Include(HitInfo.HitPositions, hiOnItemLabel);
                  end;
              else 
                if Offset < ImageOffset + TextWidth then
                  Include(HitInfo.HitPositions, hiOnItemLabel)
                else
                  Include(HitInfo.HitPositions, hiOnItemRight);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.DetermineHitPositionRTL(var HitInfo: THitInfo; Offset, Right: Integer; Alignment: TAlignment);

var
  MainColumnHit: Boolean;
  Run: PVirtualNode;
  Indent,
  TextWidth,
  ImageOffset: Integer;

begin
  MainColumnHit := HitInfo.HitColumn = FHeader.MainColumn;
  
  if MainColumnHit then
  begin
    if toFixedIndent in FOptions.FPaintOptions then
      Dec(Right, FIndent)
    else
    begin
      Run := HitInfo.HitNode;
      while (Run.Parent <> FRoot) do
      begin
        Dec(Right, FIndent);
        Run := Run.Parent;
      end;
      if toShowRoot in FOptions.FPaintOptions then
        Dec(Right, FIndent);
    end;
  end;

  if Offset >= Right then
  begin
    
    if (toShowButtons in FOptions.FPaintOptions) and (vsHasChildren in HitInfo.HitNode.States) then
    begin
      
      if Offset <= Right + Integer(FIndent) then
        Include(HitInfo.HitPositions, hiOnItemButton);
      if Offset <= Right + FPlusBM.Width then
        Include(HitInfo.HitPositions, hiOnItemButtonExact);
    end;
    
    if HitInfo.HitPositions = [] then
      Include(HitInfo.HitPositions, hiOnItemIndent);
  end
  else
  begin
    
    if MainColumnHit or not (toReportMode in FOptions.FMiscOptions) then
    begin
      ImageOffset := Right - FMargin;
      
      if MainColumnHit and (toCheckSupport in FOptions.FMiscOptions) and Assigned(FCheckImages) and
        (HitInfo.HitNode.CheckType <> ctNone) then
        Dec(ImageOffset, FCheckImages.Width + 2);

      if MainColumnHit and (Offset > ImageOffset) then
      begin
        HitInfo.HitPositions := [hiOnItem];
        if (HitInfo.HitNode.CheckType <> ctNone) then
          Include(HitInfo.HitPositions, hiOnItemCheckBox);
      end
      else
      begin
        if Assigned(FStateImages) and HasImage(HitInfo.HitNode, ikState, HitInfo.HitColumn) then
          Dec(ImageOffset, FStateImages.Width + 2);
        if Offset > ImageOffset then
          Include(HitInfo.HitPositions, hiOnStateIcon)
        else
        begin
          if Assigned(FImages) and HasImage(HitInfo.HitNode, ikNormal, HitInfo.HitColumn) then
            Dec(ImageOffset, GetNodeImageSize(HitInfo.HitNode).cx + 2);
          if Offset > ImageOffset then
            Include(HitInfo.HitPositions, hiOnNormalIcon)
          else
          begin
            
            TextWidth := DoGetNodeWidth(HitInfo.HitNode, HitInfo.HitColumn);
            
            if TextWidth > ImageOffset then
              Include(HitInfo.HitPositions, hiOnItemLabel)
            else
            begin
              
              ChangeBiDiModeAlignment(Alignment);

              case Alignment of
                taCenter:
                  begin
                    Indent := (ImageOffset - TextWidth) div 2;
                    if Offset < Indent then
                      Include(HitInfo.HitPositions, hiOnItemLeft)
                    else
                      if Offset < Indent + TextWidth then
                        Include(HitInfo.HitPositions, hiOnItemLabel)
                      else
                        Include(HitInfo.HitPositions, hiOnItemRight)
                  end;
                taRightJustify:
                  begin
                    Indent := ImageOffset - TextWidth;
                    if Offset < Indent then
                      Include(HitInfo.HitPositions, hiOnItemLeft)
                    else
                      Include(HitInfo.HitPositions, hiOnItemLabel);
                  end;
              else 
                if Offset > TextWidth then
                  Include(HitInfo.HitPositions, hiOnItemRight)
                else
                  Include(HitInfo.HitPositions, hiOnItemLabel);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

function TBaseVirtualTree.DetermineLineImageAndSelectLevel(Node: PVirtualNode; var LineImage: TLineImage): Integer;

var
  X: Integer;
  Indent: Integer;
  Run: PVirtualNode;

begin
  Result := 0;
  if toShowRoot in FOptions.FPaintOptions then
    X := 1
  else
    X := 0;
  Run := Node;
  
  while Run.Parent <> FRoot do
  begin
    Inc(X);
    Run := Run.Parent;
    
    if vsSelected in Run.States then
      Inc(Result);
  end;
  
  SetLength(LineImage, X);
  Indent := X - 1;
  
  if (toShowTreeLines in FOptions.FPaintOptions) and
     (not (toHideTreeLinesIfThemed in FOptions.FPaintOptions) or not (tsUseThemes in FStates)) then
  begin
    if toChildrenAbove in FOptions.FPaintOptions then
    begin
      Dec(X);
      if not HasVisiblePreviousSibling(Node) then
      begin
        if (Node.Parent <> FRoot) or HasVisibleNextSibling(Node) then
          LineImage[X] := ltBottomRight
        else
          LineImage[X] := ltRight;
      end
      else
        if (Node.Parent = FRoot) and (not HasVisibleNextSibling(Node)) then
          LineImage[X] := ltTopRight
        else
          LineImage[X] := ltTopDownRight;
      
      Run := Node.Parent;
      while Run <> FRoot do
      begin
        Dec(X);
        if HasVisiblePreviousSibling(Run) then
          LineImage[X] := ltTopDown
        else
          LineImage[X] := ltNone;

        Run := Run.Parent;
      end;
    end
    else
    begin
      
      Run := Node;

      if Run.Parent <> FRoot then
      begin
        
        if HasVisibleNextSibling(Run) then
          LineImage[X - 1] := ltTopDownRight
        else
          LineImage[X - 1] := ltTopRight;
        Run := Run.Parent;
        
        repeat
          if Run.Parent = FRoot then
            Break;
          Dec(X);
          if HasVisibleNextSibling(Run) then
            LineImage[X - 1] := ltTopDown
          else
            LineImage[X - 1] := ltNone;
          Run := Run.Parent;
        until False;
      end;
      
      if (toShowRoot in FOptions.FPaintOptions) and ((toShowTreeLines in FOptions.FPaintOptions) and
         (not (toHideTreeLinesIfThemed in FOptions.FPaintOptions) or not (tsUseThemes in FStates))) then
      begin
        
        if Run = Node then
        begin
          
          if IsFirstVisibleChild(FRoot, Run) then
            
            if IsLastVisibleChild(FRoot, Run) then
              LineImage[0] := ltRight
            else
              LineImage[0] := ltBottomRight
          else
            
            if IsLastVisibleChild(FRoot, Run) then
              LineImage[0] := ltTopRight
            else
              LineImage[0] := ltTopDownRight;
        end
        else
        begin
          
          if HasVisibleNextSibling(Run) then
            LineImage[0] := ltTopDown
          else
            LineImage[0] := ltNone;
        end;
      end;
    end;
  end;

  if (tsUseExplorerTheme in FStates) and HasChildren[Node] and (Indent >= 0) then
    LineImage[Indent] := ltNone;
end;

function TBaseVirtualTree.DetermineNextCheckState(CheckType: TCheckType; CheckState: TCheckState): TCheckState;

begin
  case CheckType of
    ctTriStateCheckBox,
    ctCheckBox:
      if CheckState = csCheckedNormal then
        Result := csUncheckedNormal
      else
        Result := csCheckedNormal;
    ctRadioButton:
      Result := csCheckedNormal;
    ctButton:
      Result := csUncheckedNormal;
  else
    Result := csMixedNormal;
  end;
end;

function TBaseVirtualTree.DetermineScrollDirections(X, Y: Integer): TScrollDirections;

begin
  Result:= [];

  if CanAutoScroll then
  begin
    
    if [tsWheelPanning, tsWheelScrolling] * FStates <> [] then
    begin
      if (X - FLastClickPos.X) < -8 then
        Include(Result, sdLeft);
      if (X - FLastClickPos.X) > 8 then
        Include(Result, sdRight);

      if (Y - FLastClickPos.Y) < -8 then
        Include(Result, sdUp);
      if (Y - FLastClickPos.Y) > 8 then
        Include(Result, sdDown);
    end
    else
    begin
      if (X < Integer(FDefaultNodeHeight)) and (FEffectiveOffsetX <> 0) then
        Include(Result, sdLeft);
      if (ClientWidth + FEffectiveOffsetX < Integer(FRangeX)) and (X > ClientWidth - Integer(FDefaultNodeHeight)) then
        Include(Result, sdRight);

      if (Y < Integer(FDefaultNodeHeight)) and (FOffsetY <> 0) then
        Include(Result, sdUp);
      if (ClientHeight - FOffsetY < Integer(FRangeY)) and (Y > ClientHeight - Integer(FDefaultNodeHeight)) then
        Include(Result, sdDown);
      
      if (Result <> []) and
        ((Assigned(FDragManager) and DragManager.IsDropTarget) or
        (FindDragTarget(Point(X, Y), False) = Self)) then
      begin
        if FDragScrollStart = 0 then
          FDragScrollStart := timeGetTime;
        
        if ((timeGetTime - FDragScrollStart) < FAutoScrollDelay) then
          Result := [];
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.DoAdvancedHeaderDraw(var PaintInfo: THeaderPaintInfo; const Elements: THeaderPaintElements);

begin
  if Assigned(FOnAdvancedHeaderDraw) then
    FOnAdvancedHeaderDraw(FHeader, PaintInfo, Elements);
end;

procedure TBaseVirtualTree.DoAfterCellPaint(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);

begin
  if Assigned(FOnAfterCellPaint) then
    FOnAfterCellPaint(Self, Canvas, Node, Column, CellRect);
end;

procedure TBaseVirtualTree.DoAfterItemErase(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect);

begin
  if Assigned(FOnAfterItemErase) then
    FOnAfterItemErase(Self, Canvas, Node, ItemRect);
end;

procedure TBaseVirtualTree.DoAfterItemPaint(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect);

begin
  if Assigned(FOnAfterItemPaint) then
    FOnAfterItemPaint(Self, Canvas, Node, ItemRect);
end;

procedure TBaseVirtualTree.DoAfterPaint(Canvas: TCanvas);

begin
  if Assigned(FOnAfterPaint) then
    FOnAfterPaint(Self, Canvas);
end;

procedure TBaseVirtualTree.DoAutoScroll(X, Y: Integer);

begin
  FScrollDirections := DetermineScrollDirections(X, Y);

  if FStates * [tsWheelPanning, tsWheelScrolling] = [] then
  begin
    if FScrollDirections = [] then
    begin
      if ((FStates * [tsScrollPending, tsScrolling]) <> []) then
      begin
        StopTimer(ScrollTimer);
        DoStateChange([], [tsScrollPending, tsScrolling]);
      end;
    end
    else
    begin
      
      if (FStates * [tsScrollPending, tsScrolling]) = [] then
      begin
        DoStateChange([tsScrollPending]);
        SetTimer(Handle, ScrollTimer, FAutoScrollDelay, nil);
      end;
    end;
  end;
end;

function TBaseVirtualTree.DoBeforeDrag(Node: PVirtualNode; Column: TColumnIndex): Boolean;

begin
  Result := False;
  if Assigned(FOnDragAllowed) then
    FOnDragAllowed(Self, Node, Column, Result);
end;

procedure TBaseVirtualTree.DoBeforeCellPaint(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);

var
  UpdateRect: TRect;

begin
  if Assigned(FOnBeforeCellPaint) then
  begin
    if CellPaintMode = cpmGetContentMargin then
    begin
      
      GetUpdateRect(Handle, UpdateRect, False);
      SetUpdateState(True);
    end;

    Canvas.Font := Self.Font; 
    FOnBeforeCellPaint(Self, Canvas, Node, Column, CellPaintMode, CellRect, ContentRect);

    if CellPaintMode = cpmGetContentMargin then
    begin
      SetUpdateState(False);
      InvalidateRect(Handle, @UpdateRect, False);
    end;
  end;
end;

procedure TBaseVirtualTree.DoBeforeItemErase(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect; var Color: TColor;
  var EraseAction: TItemEraseAction);

begin
  if Assigned(FOnBeforeItemErase) then
    FOnBeforeItemErase(Self, Canvas, Node, ItemRect, Color, EraseAction);
end;

function TBaseVirtualTree.DoBeforeItemPaint(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect): Boolean;

begin
  
  Result := False;
  if Assigned(FOnBeforeItemPaint) then
    FOnBeforeItemPaint(Self, Canvas, Node, ItemRect, Result);
end;

procedure TBaseVirtualTree.DoBeforePaint(Canvas: TCanvas);

begin
  if Assigned(FOnBeforePaint) then
    FOnBeforePaint(Self, Canvas);
end;

function TBaseVirtualTree.DoCancelEdit: Boolean;

begin
  StopTimer(EditTimer);
  DoStateChange([], [tsEditPending]);
  Result := (tsEditing in FStates) and FEditLink.CancelEdit;
  if Result then
  begin
    DoStateChange([], [tsEditing]);
    if Assigned(FOnEditCancelled) then
      FOnEditCancelled(Self, FEditColumn);
    if not (csDestroying in ComponentState) then
      FEditLink := nil;
  end;
end;

procedure TBaseVirtualTree.DoCanEdit(Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean);

begin
  if Assigned(FOnEditing) then
    FOnEditing(Self, Node, Column, Allowed);
end;

procedure TBaseVirtualTree.DoCanSplitterResizeNode(P: TPoint; Node: PVirtualNode; Column: TColumnIndex;
  var Allowed: Boolean);

begin
  if Assigned(FOnCanSplitterResizeNode) then
    FOnCanSplitterResizeNode(Self, P, Node, Column, Allowed);
end;

procedure TBaseVirtualTree.DoChange(Node: PVirtualNode);

begin
  StopTimer(ChangeTimer);
  if Assigned(FOnChange) then
    FOnChange(Self, Node);
  
  DoStateChange([], [tsChangePending]);
  FLastChangedNode := nil;
end;

procedure TBaseVirtualTree.DoCheckClick(Node: PVirtualNode; NewCheckState: TCheckState);

begin
  if ChangeCheckState(Node, NewCheckState) then
    DoChecked(Node);
end;

procedure TBaseVirtualTree.DoChecked(Node: PVirtualNode);

begin
  if Assigned(FOnChecked) then
    FOnChecked(Self, Node);
  if Assigned(FAccessibleItem) then
    NotifyWinEvent(EVENT_OBJECT_STATECHANGE, Handle, OBJID_CLIENT, CHILDID_SELF);
end;

function TBaseVirtualTree.DoChecking(Node: PVirtualNode; var NewCheckState: TCheckState): Boolean;

begin
  if toReadOnly in FOptions.FMiscOptions then
    Result := False
  else
  begin
    Result := True;
    if Assigned(FOnChecking) then
      FOnChecking(Self, Node, NewCheckState, Result);
  end;
end;

procedure TBaseVirtualTree.DoCollapsed(Node: PVirtualNode);

begin
  if Assigned(FOnCollapsed) then
    FOnCollapsed(Self, Node);

  if Assigned(FAccessibleItem) then
    NotifyWinEvent(EVENT_OBJECT_STATECHANGE, Handle, OBJID_CLIENT, CHILDID_SELF);
end;

function TBaseVirtualTree.DoCollapsing(Node: PVirtualNode): Boolean;

begin
  Result := True;
  if Assigned(FOnCollapsing) then
    FOnCollapsing(Self, Node, Result);
end;

procedure TBaseVirtualTree.DoColumnClick(Column: TColumnIndex; Shift: TShiftState);

begin
  if Assigned(FOnColumnClick) then
    FOnColumnClick(Self, Column, Shift);
end;

procedure TBaseVirtualTree.DoColumnDblClick(Column: TColumnIndex; Shift: TShiftState);

begin
  if Assigned(FOnColumnDblClick) then
    FOnColumnDblClick(Self, Column, Shift);
end;

procedure TBaseVirtualTree.DoColumnResize(Column: TColumnIndex);

var
  R: TRect;
  Run: PVirtualNode;

begin
  if not (csLoading in ComponentState) and HandleAllocated then
  begin
    
    Run := GetFirstInitialized;
    while Assigned(Run) do
    begin
      if vsMultiline in Run.States then
        Exclude(Run.States, vsHeightMeasured);
      Run := GetNextInitialized(Run);
    end;

    UpdateHorizontalScrollBar(True);
    if Column > NoColumn then
    begin
      
      R := ClientRect;
      if not (toAutoSpanColumns in FOptions.FAutoOptions) then
        if UseRightToLeftAlignment then
          R.Right := FHeader.Columns[Column].Left + FHeader.Columns[Column].Width + ComputeRTLOffset
        else
          R.Left := FHeader.Columns[Column].Left;
      InvalidateRect(Handle, @R, False);
      FHeader.Invalidate(FHeader.Columns[Column], True);
    end;
    if [hsColumnWidthTracking, hsResizing] * FHeader.States = [hsColumnWidthTracking] then
      UpdateWindow(Handle);

    if not (tsUpdating in FStates) then
      UpdateDesigner; 

    if Assigned(FOnColumnResize) and not (hsResizing in FHeader.States) then
      FOnColumnResize(FHeader, Column);
    
    if tsEditing in FStates then
      UpdateEditBounds;
  end;
end;

function TBaseVirtualTree.DoCompare(Node1, Node2: PVirtualNode; Column: TColumnIndex): Integer;

begin
  Result := 0;
  if Assigned(FOnCompareNodes) then
    FOnCompareNodes(Self, Node1, Node2, Column, Result);
end;

function TBaseVirtualTree.DoCreateDataObject: IDataObject;

begin
  Result := nil;
  if Assigned(FOnCreateDataObject) then
    FOnCreateDataObject(Self, Result);
end;

function TBaseVirtualTree.DoCreateDragManager: IVTDragManager;

begin
  Result := nil;
  if Assigned(FOnCreateDragManager) then
    FOnCreateDragManager(Self, Result);
end;

function TBaseVirtualTree.DoCreateEditor(Node: PVirtualNode; Column: TColumnIndex): IVTEditLink;

begin
  Result := nil;
  if Assigned(FOnCreateEditor) then
    FOnCreateEditor(Self, Node, Column, Result);
end;

procedure TBaseVirtualTree.DoDragging(P: TPoint);

  function GetDragOperations: Integer;

  begin
    if FDragOperations = [] then
      Result := DROPEFFECT_COPY or DROPEFFECT_MOVE or DROPEFFECT_LINK
    else
    begin
      Result := 0;
      if doCopy in FDragOperations then
        Result := Result or DROPEFFECT_COPY;
      if doLink in FDragOperations then
        Result := Result or DROPEFFECT_LINK;
      if doMove in FDragOperations then
        Result := Result or DROPEFFECT_MOVE;
    end;
  end;

var
  AllowedEffects: LongInt;
  DragObject: TDragObject;

  DataObject: IDataObject;

begin
  DataObject := nil;
  
  DoCancelEdit;

  if Assigned(FCurrentHotNode) then
  begin
    InvalidateNode(FCurrentHotNode);
    FCurrentHotNode := nil;
  end;
  
  if Assigned(FFocusedNode) and not (vsSelected in FFocusedNode.States) then
  begin
    InternalAddToSelection(FFocusedNode, False);
    InvalidateNode(FFocusedNode);
  end;

  UpdateWindow(Handle);
  
  FDragSelection := GetSortedSelection(True);
  try
    DoStateChange([tsOLEDragging], [tsOLEDragPending, tsClearPending]);
    
    DragObject := nil;
    DoStartDrag(DragObject);
    DragObject.Free;

    DataObject := DragManager.DataObject;
    PrepareDragImage(P, DataObject);

    FLastDropMode := dmOnNode;
    
    FLastDragEffect := DROPEFFECT_NONE;
    AllowedEffects := GetDragOperations;
    try
      DragAndDrop(AllowedEffects, DataObject, FLastDragEffect);
      DragManager.ForceDragLeave;
    finally
      GetCursorPos(P);
      P := ScreenToClient(P);
      DoEndDrag(Self, P.X, P.Y);

      FDragImage.EndDrag;
      
      if (FLastDragEffect = DROPEFFECT_MOVE) and (toAutoDeleteMovedNodes in TreeOptions.AutoOptions) then
      begin
        
        DeleteSelectedNodes;
      end;

      DoStateChange([], [tsOLEDragging]);
    end;
  finally
    FDragSelection := nil;
  end;
end;

procedure TBaseVirtualTree.DoDragExpand;

var
  SourceTree: TBaseVirtualTree;

begin
  StopTimer(ExpandTimer);
  if Assigned(FDropTargetNode) and (vsHasChildren in FDropTargetNode.States) and
    not (vsExpanded in FDropTargetNode.States) then
  begin
    if Assigned(FDragManager) then
      SourceTree := DragManager.DragSource
    else
      SourceTree := nil;

    if not DragManager.DropTargetHelperSupported and Assigned(SourceTree) then
      SourceTree.FDragImage.HideDragImage;
    ToggleNode(FDropTargetNode);
    UpdateWindow(Handle);
    if not DragManager.DropTargetHelperSupported and Assigned(SourceTree) then
      SourceTree.FDragImage.ShowDragImage;
  end;
end;

function TBaseVirtualTree.DoDragOver(Source: TObject; Shift: TShiftState; State: TDragState; Pt: TPoint; Mode: TDropMode;
  var Effect: Integer): Boolean;

begin
  Result := False;
  if Assigned(FOnDragOver) then
    FOnDragOver(Self, Source, Shift, State, Pt, Mode, Effect, Result);
end;

procedure TBaseVirtualTree.DoDragDrop(Source: TObject; DataObject: IDataObject; Formats: TFormatArray;
  Shift: TShiftState; Pt: TPoint; var Effect: Integer; Mode: TDropMode);

begin
  if Assigned(FOnDragDrop) then
    FOnDragDrop(Self, Source, DataObject, Formats, Shift, Pt, Effect, Mode);
end;

procedure TBaseVirtualTree.DoBeforeDrawLineImage(Node: PVirtualNode; Level: Integer; var XPos: Integer);

begin
  if Assigned(FOnBeforeDrawLineImage) then
    FOnBeforeDrawLineImage(Self, Node, Level, XPos);
end;

procedure TBaseVirtualTree.DoEdit;

begin
  Application.CancelHint;
  StopTimer(ScrollTimer);
  StopTimer(EditTimer);
  DoStateChange([], [tsEditPending]);
  if Assigned(FFocusedNode) and not (vsDisabled in FFocusedNode.States) and
    not (toReadOnly in FOptions.FMiscOptions) and (FEditLink = nil) then
  begin
    FEditLink := DoCreateEditor(FFocusedNode, FEditColumn);
    if Assigned(FEditLink) then
    begin
      DoStateChange([tsEditing], [tsDrawSelecting, tsDrawSelPending, tsToggleFocusedSelection, tsOLEDragPending,
        tsOLEDragging, tsClearPending, tsDrawSelPending, tsScrollPending, tsScrolling, tsMouseCheckPending]);
      ScrollIntoView(FFocusedNode, toCenterScrollIntoView in FOptions.SelectionOptions,
        not (toDisableAutoscrollOnEdit in FOptions.AutoOptions));
      if FEditLink.PrepareEdit(Self, FFocusedNode, FEditColumn) then
      begin
        UpdateEditBounds;
        
        InvalidateNode(FFocusedNode);
        if not FEditLink.BeginEdit then
          DoStateChange([], [tsEditing]);
      end
      else
        DoStateChange([], [tsEditing]);
      if not (tsEditing in FStates) then
        FEditLink := nil;
    end;
  end;
end;

procedure TBaseVirtualTree.DoEndDrag(Target: TObject; X, Y: Integer);

begin
  inherited;

  DragFinished;
end;

function TBaseVirtualTree.DoEndEdit: Boolean;

begin
  StopTimer(EditTimer);
  Result := (tsEditing in FStates) and FEditLink.EndEdit;
  if Result then
  begin
    DoStateChange([], [tsEditing]);
    FEditLink := nil;
    if Assigned(FOnEdited) then
      FOnEdited(Self, FFocusedNode, FEditColumn);
  end;
  DoStateChange([], [tsEditPending]);
end;

procedure TBaseVirtualTree.DoEndOperation(OperationKind: TVTOperationKind);

begin
  if Assigned(FOnEndOperation) then
    FOnEndOperation(Self, OperationKind);
end;

procedure TBaseVirtualTree.DoEnter();
begin
  inherited;
end;

procedure TBaseVirtualTree.DoExpanded(Node: PVirtualNode);

begin
  if Assigned(FOnExpanded) then
    FOnExpanded(Self, Node);

  if Assigned(FAccessibleItem) then
    NotifyWinEvent(EVENT_OBJECT_STATECHANGE, Handle, OBJID_CLIENT, CHILDID_SELF);
end;

function TBaseVirtualTree.DoExpanding(Node: PVirtualNode): Boolean;

begin
  Result := True;
  if Assigned(FOnExpanding) then
    FOnExpanding(Self, Node, Result);
end;

procedure TBaseVirtualTree.DoFocusChange(Node: PVirtualNode; Column: TColumnIndex);

begin
  if Assigned(FOnFocusChanged) then
    FOnFocusChanged(Self, Node, Column);

  if Assigned(FAccessibleItem) then
  begin
    NotifyWinEvent(EVENT_OBJECT_LOCATIONCHANGE, Handle, OBJID_CLIENT, CHILDID_SELF);
    NotifyWinEvent(EVENT_OBJECT_NAMECHANGE, Handle, OBJID_CLIENT, CHILDID_SELF);
    NotifyWinEvent(EVENT_OBJECT_VALUECHANGE, Handle, OBJID_CLIENT, CHILDID_SELF);
    NotifyWinEvent(EVENT_OBJECT_STATECHANGE, Handle, OBJID_CLIENT, CHILDID_SELF);
    NotifyWinEvent(EVENT_OBJECT_SELECTION, Handle, OBJID_CLIENT, CHILDID_SELF);
    NotifyWinEvent(EVENT_OBJECT_FOCUS, Handle, OBJID_CLIENT, CHILDID_SELF);
  end;
end;

function TBaseVirtualTree.DoFocusChanging(OldNode, NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex): Boolean;

begin
  Result := (OldColumn = NewColumn) or FHeader.AllowFocus(NewColumn);
  if Assigned(FOnFocusChanging) then
    FOnFocusChanging(Self, OldNode, NewNode, OldColumn, NewColumn, Result);
end;

procedure TBaseVirtualTree.DoFocusNode(Node: PVirtualNode; Ask: Boolean);

begin
  if not (tsEditing in FStates) or EndEditNode then
  begin
    if Node = FRoot then
      Node := nil;
    if (FFocusedNode <> Node) and (not Ask or DoFocusChanging(FFocusedNode, Node, FFocusedColumn, FFocusedColumn)) then
    begin
      if Assigned(FFocusedNode) then
      begin
        
        if (toAutoExpand in FOptions.FAutoOptions) and Assigned(Node) and (Node.Parent = FFocusedNode.Parent) and
          (vsExpanded in FFocusedNode.States) then
          ToggleNode(FFocusedNode)
        else
          InvalidateNode(FFocusedNode);
      end;
      FFocusedNode := Node;
    end;
    
    if Assigned(FFocusedNode) then
    begin
      
      if FHeader.UseColumns and (not FHeader.FColumns.IsValidColumn(FFocusedColumn)) then
        FFocusedColumn := FHeader.MainColumn;
      
      if (toAutoExpand in FOptions.FAutoOptions) and not (vsExpanded in FFocusedNode.States) then
        ToggleNode(FFocusedNode);
      InvalidateNode(FFocusedNode);
      if (FUpdateCount = 0) and not (toDisableAutoscrollOnFocus in FOptions.FAutoOptions) then
        ScrollIntoView(FFocusedNode, (toCenterScrollIntoView in FOptions.SelectionOptions) and
          (MouseButtonDown * FStates = []), not (toFullRowSelect in FOptions.SelectionOptions) );
    end;
    
    if FSelectionCount = 0 then
      ResetRangeAnchor;
  end;
end;

procedure TBaseVirtualTree.DoFreeNode(Node: PVirtualNode);

begin
  if Node = FLastChangedNode then
    FLastChangedNode := nil;
  if Node = FCurrentHotNode then
    FCurrentHotNode := nil;
  if Node = FDropTargetNode then
    FDropTargetNode := nil;
  if Node = FLastStructureChangeNode then
    FLastStructureChangeNode := nil;
  if Assigned(FOnFreeNode) and ([vsInitialized, vsOnFreeNodeCallRequired] * Node.States <> []) then
    FOnFreeNode(Self, Node);
  FreeMem(Node);
end;

const
  SPI_GETTOOLTIPANIMATION = $1016;
  SPI_GETTOOLTIPFADE = $1018;

function TBaseVirtualTree.DoGetAnimationType: THintAnimationType;

var
  Animation: BOOL;

begin
  Result := FAnimationType;
  if Result = hatSystemDefault then
  begin
    SystemParametersInfo(SPI_GETTOOLTIPANIMATION, 0, @Animation, 0);
    if not Animation then
      Result := hatNone
    else
    begin
      SystemParametersInfo(SPI_GETTOOLTIPFADE, 0, @Animation, 0);
      if Animation then
        Result := hatFade
      else
        Result := hatSlide;
    end;
  end;
  
  if not MMXAvailable and (Result = hatFade) then
    Result := hatSlide;
end;

function TBaseVirtualTree.DoGetCellContentMargin(Node: PVirtualNode; Column: TColumnIndex;
  CellContentMarginType: TVTCellContentMarginType = ccmtAllSides; Canvas: TCanvas = nil): TPoint;

var
  CellRect,
  ContentRect: TRect;

begin
  Result := Point(0, 0);

  if Assigned(FOnBeforeCellPaint) then 
  begin
    if Canvas = nil then
      Canvas := Self.Canvas;
    
    CellRect := GetDisplayRect(Node, Column, True);
    ContentRect := CellRect;
    DoBeforeCellPaint(Canvas, Node, Column, cpmGetContentMargin, CellRect, ContentRect);
    
    case CellContentMarginType of
      ccmtAllSides:
        
        Result := Point((CellRect.Right - CellRect.Left) - (ContentRect.Right - ContentRect.Left),
                        (CellRect.Bottom - CellRect.Top) - (ContentRect.Bottom - ContentRect.Top));
      ccmtTopLeftOnly:
        
        Result := Point(ContentRect.Left - CellRect.Left, ContentRect.Top - CellRect.Top);
      ccmtBottomRightOnly:
        
        Result := Point(CellRect.Right - ContentRect.Right, CellRect.Bottom - ContentRect.Bottom);
    end;
  end;
end;

procedure TBaseVirtualTree.DoGetCursor(var Cursor: TCursor);

begin
  if Assigned(FOnGetCursor) then
    FOnGetCursor(Self, Cursor);
end;

procedure TBaseVirtualTree.DoGetHeaderCursor(var Cursor: HCURSOR);

begin
  if Assigned(FOnGetHeaderCursor) then
    FOnGetHeaderCursor(FHeader, Cursor);
end;

function TBaseVirtualTree.DoGetImageIndex(Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var Index: Integer): TCustomImageList;

begin
  Result := nil;
  
  if Assigned(FOnGetImageEx) then
    FOnGetImageEx(Self, Node, Kind, Column, Ghosted, Index, Result)
  else
    if Assigned(FOnGetImage) then
      FOnGetImage(Self, Node, Kind, Column, Ghosted, Index);
end;

procedure TBaseVirtualTree.DoGetImageText(Node: PVirtualNode; Kind: TVTImageKind;
  Column: TColumnIndex; var ImageText: UnicodeString);

begin
  if Assigned(FOnGetImageText) then
     FOnGetImageText(Self, Node, Kind, Column, ImageText);
end;

procedure TBaseVirtualTree.DoGetLineStyle(var Bits: Pointer);

begin
  if Assigned(FOnGetLineStyle) then
    FOnGetLineStyle(Self, Bits);
end;

function TBaseVirtualTree.DoGetNodeHint(Node: PVirtualNode; Column: TColumnIndex;
  var LineBreakStyle: TVTTooltipLineBreakStyle): UnicodeString;

begin
  Result := Hint;
  LineBreakStyle := hlbDefault;
end;

function TBaseVirtualTree.DoGetNodeTooltip(Node: PVirtualNode; Column: TColumnIndex;
  var LineBreakStyle: TVTTooltipLineBreakStyle): UnicodeString;

begin
  Result := Hint;
  LineBreakStyle := hlbDefault;
end;

function TBaseVirtualTree.DoGetNodeExtraWidth(Node: PVirtualNode; Column: TColumnIndex; Canvas: TCanvas = nil): Integer;

begin
  Result := 0;
end;

function TBaseVirtualTree.DoGetNodeWidth(Node: PVirtualNode; Column: TColumnIndex; Canvas: TCanvas = nil): Integer;

begin
  Result := 0;
end;

function TBaseVirtualTree.DoGetPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint): TPopupMenu;

var
  Run: PVirtualNode;
  AskParent: Boolean;

begin
  Result := nil;
  if Assigned(FOnGetPopupMenu) then
  begin
    Run := Node;

    if Assigned(Run) then
    begin
      AskParent := True;
      repeat
        FOnGetPopupMenu(Self, Run, Column, Position, AskParent, Result);
        Run := Run.Parent;
      until (Run = FRoot) or Assigned(Result) or not AskParent;
    end
    else
      FOnGetPopupMenu(Self, nil, -1, Position, AskParent, Result);
  end;
end;

procedure TBaseVirtualTree.DoGetUserClipboardFormats(var Formats: TFormatEtcArray);

begin
  if Assigned(FOnGetUserClipboardFormats) then
    FOnGetUserClipboardFormats(Self, Formats);
end;

procedure TBaseVirtualTree.DoHeaderClick(HitInfo: TVTHeaderHitInfo);

begin
  if Assigned(FOnHeaderClick) then
    FOnHeaderClick(FHeader, HitInfo);
end;

procedure TBaseVirtualTree.DoHeaderDblClick(HitInfo: TVTHeaderHitInfo);

begin
  if Assigned(FOnHeaderDblClick) then
    FOnHeaderDblClick(FHeader, HitInfo);
end;

procedure TBaseVirtualTree.DoHeaderDragged(Column: TColumnIndex; OldPosition: TColumnPosition);

begin
  if Assigned(FOnHeaderDragged) then
    FOnHeaderDragged(FHeader, Column, OldPosition);
end;

procedure TBaseVirtualTree.DoHeaderDraggedOut(Column: TColumnIndex; DropPosition: TPoint);

begin
  if Assigned(FOnHeaderDraggedOut) then
    FOnHeaderDraggedOut(FHeader, Column, DropPosition);
end;

function TBaseVirtualTree.DoHeaderDragging(Column: TColumnIndex): Boolean;

begin
  Result := True;
  if Assigned(FOnHeaderDragging) then
    FOnHeaderDragging(FHeader, Column, Result);
end;

procedure TBaseVirtualTree.DoHeaderDraw(Canvas: TCanvas; Column: TVirtualTreeColumn; R: TRect; Hover, Pressed: Boolean;
  DropMark: TVTDropMarkMode);

begin
  if Assigned(FOnHeaderDraw) then
    FOnHeaderDraw(FHeader, Canvas, Column, R, Hover, Pressed, DropMark);
end;

procedure TBaseVirtualTree.DoHeaderDrawQueryElements(var PaintInfo: THeaderPaintInfo; var Elements: THeaderPaintElements);

begin
  if Assigned(FOnHeaderDrawQueryElements) then
    FOnHeaderDrawQueryElements(FHeader, PaintInfo, Elements);
end;

procedure TBaseVirtualTree.DoHeaderMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

begin
  if Assigned(FOnHeaderMouseDown) then
    FOnHeaderMouseDown(FHeader, Button, Shift, X, Y);
end;

procedure TBaseVirtualTree.DoHeaderMouseMove(Shift: TShiftState; X, Y: Integer);

begin
  if Assigned(FOnHeaderMouseMove) then
    FOnHeaderMouseMove(FHeader, Shift, X, Y);
end;

procedure TBaseVirtualTree.DoHeaderMouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

begin
  if Assigned(FOnHeaderMouseUp) then
    FOnHeaderMouseUp(FHeader, Button, Shift, X, Y);
end;

procedure TBaseVirtualTree.DoHotChange(Old, New: PVirtualNode);

begin
  if Assigned(FOnHotChange) then
    FOnHotChange(Self, Old, New);
end;

function TBaseVirtualTree.DoIncrementalSearch(Node: PVirtualNode; const Text: UnicodeString): Integer;

begin
  Result := 0;
  if Assigned(FOnIncrementalSearch) then
    FOnIncrementalSearch(Self, Node, Text, Result);
end;

procedure TBaseVirtualTree.DoInitChildren(Node: PVirtualNode; var ChildCount: Cardinal);

begin
  if Assigned(FOnInitChildren) then
    FOnInitChildren(Self, Node, ChildCount);
end;

procedure TBaseVirtualTree.DoInitNode(Parent, Node: PVirtualNode; var InitStates: TVirtualNodeInitStates);

begin
  if Assigned(FOnInitNode) then
    FOnInitNode(Self, Parent, Node, InitStates);
end;

function TBaseVirtualTree.DoKeyAction(var CharCode: Word; var Shift: TShiftState): Boolean;

begin
  Result := True;
  if Assigned(FOnKeyAction) then
    FOnKeyAction(Self, CharCode, Shift, Result);
end;

procedure TBaseVirtualTree.DoLoadUserData(Node: PVirtualNode; Stream: TStream);

begin
  if Assigned(FOnLoadNode) then
    if Node = FRoot then
      FOnLoadNode(Self, nil, Stream)
    else
      FOnLoadNode(Self, Node, Stream);
end;

procedure TBaseVirtualTree.DoMeasureItem(TargetCanvas: TCanvas; Node: PVirtualNode; var NodeHeight: Integer);

begin
  if Assigned(FOnMeasureItem) then
    FOnMeasureItem(Self, TargetCanvas, Node, NodeHeight);
end;

procedure TBaseVirtualTree.DoMouseEnter();
begin
  if Assigned(FOnMouseEnter) then
    FOnMouseEnter(Self);
end;

procedure TBaseVirtualTree.DoMouseLeave;
begin
  if Assigned(FOnMouseLeave) then
    FOnMouseLeave(Self);
end;

procedure TBaseVirtualTree.DoNodeCopied(Node: PVirtualNode);

begin
  if Assigned(FOnNodeCopied) then
    FOnNodeCopied(Self, Node);
end;

function TBaseVirtualTree.DoNodeCopying(Node, NewParent: PVirtualNode): Boolean;

begin
  Result := True;
  if Assigned(FOnNodeCopying) then
    FOnNodeCopying(Self, Node, NewParent, Result);
end;

procedure TBaseVirtualTree.DoNodeClick(const HitInfo: THitInfo);

begin
  if Assigned(FOnNodeClick) then
    FOnNodeClick(Self, HitInfo);
end;

procedure TBaseVirtualTree.DoNodeDblClick(const HitInfo: THitInfo);

begin
  if Assigned(FOnNodeDblClick) then
    FOnNodeDblClick(Self, HitInfo);
end;

function TBaseVirtualTree.DoNodeHeightDblClickResize(Node: PVirtualNode; Column: TColumnIndex; Shift: TShiftState;
  P: TPoint): Boolean;

begin
  Result := True;
  if Assigned(FOnNodeHeightDblClickResize) then
    FOnNodeHeightDblClickResize(Self, Node, Column, Shift, P, Result);
end;

function TBaseVirtualTree.DoNodeHeightTracking(Node: PVirtualNode; Column: TColumnIndex; Shift: TShiftState;
  var TrackPoint: TPoint; P: TPoint): Boolean;

begin
  Result := True;
  if Assigned(FOnNodeHeightTracking) then
    FOnNodeHeightTracking(Self, Node, Column, Shift, TrackPoint, P, Result);
end;

procedure TBaseVirtualTree.DoNodeMoved(Node: PVirtualNode);

begin
  if Assigned(FOnNodeMoved) then
    FOnNodeMoved(Self, Node);
end;

function TBaseVirtualTree.DoNodeMoving(Node, NewParent: PVirtualNode): Boolean;

begin
  Result := True;
  if Assigned(FOnNodeMoving) then
    FOnNodeMoving(Self, Node, NewParent, Result);
end;

function TBaseVirtualTree.DoPaintBackground(Canvas: TCanvas; R: TRect): Boolean;

begin
  Result := False;
  if Assigned(FOnPaintBackground) then
    FOnPaintBackground(Self, Canvas, R, Result);
end;

procedure TBaseVirtualTree.DoPaintDropMark(Canvas: TCanvas; Node: PVirtualNode; R: TRect);

var
  SaveBrushColor: TColor;
  SavePenStyle: TPenStyle;

begin
  if FLastDropMode in [dmAbove, dmBelow] then
    with Canvas do
    begin
      SavePenStyle := Pen.Style;
      Pen.Style := psClear;
      SaveBrushColor := Brush.Color;
      Brush.Color := FColors.DropMarkColor;

      if FLastDropMode = dmAbove then
      begin
        Polygon([Point(R.Left + 2, R.Top),
                 Point(R.Right - 2, R.Top),
                 Point(R.Right - 2, R.Top + 6),
                 Point(R.Right - 6, R.Top + 2),
                 Point(R.Left + 6 , R.Top + 2),
                 Point(R.Left + 2, R.Top + 6)
        ]);
      end
      else
        Polygon([Point(R.Left + 2, R.Bottom - 1),
                 Point(R.Right - 2, R.Bottom - 1),
                 Point(R.Right - 2, R.Bottom - 8),
                 Point(R.Right - 7, R.Bottom - 3),
                 Point(R.Left + 7 , R.Bottom - 3),
                 Point(R.Left + 2, R.Bottom - 8)
        ]);
      Brush.Color := SaveBrushColor;
      Pen.Style := SavePenStyle;
    end;
end;

procedure TBaseVirtualTree.DoPaintNode(var PaintInfo: TVTPaintInfo);

begin
end;

procedure TBaseVirtualTree.DoPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint);

var
  Menu: TPopupMenu;

begin
  Menu := DoGetPopupMenu(Node, Column, Position);

  if Assigned(Menu) then
  begin
    DoStateChange([tsPopupMenuShown]);
    StopTimer(EditTimer);
    Menu.PopupComponent := Self;
    with ClientToScreen(Position) do
      Menu.Popup(X, Y);
  end;
end;

procedure TBaseVirtualTree.DoRemoveFromSelection(Node: PVirtualNode);
begin
  if Assigned(FOnRemoveFromSelection) then
    FOnRemoveFromSelection(Self, Node);
end;

function TBaseVirtualTree.DoRenderOLEData(const FormatEtcIn: TFormatEtc; out Medium: TStgMedium;
  ForClipboard: Boolean): HRESULT;

begin
  Result := E_FAIL;
  if Assigned(FOnRenderOLEData) then
    FOnRenderOLEData(Self, FormatEtcIn, Medium, ForClipboard, Result);
end;

procedure TBaseVirtualTree.DoReset(Node: PVirtualNode);

begin
  if Assigned(FOnResetNode) then
    FOnResetNode(Self, Node);
end;

procedure TBaseVirtualTree.DoSaveUserData(Node: PVirtualNode; Stream: TStream);

begin
  if Assigned(FOnSaveNode) then
    if Node = FRoot then
      FOnSaveNode(Self, nil, Stream)
    else
      FOnSaveNode(Self, Node, Stream);
end;

procedure TBaseVirtualTree.DoScroll(DeltaX, DeltaY: Integer);

begin
  if Assigned(FOnScroll) then
    FOnScroll(Self, DeltaX, DeltaY);
end;

function TBaseVirtualTree.DoSetOffsetXY(Value: TPoint; Options: TScrollUpdateOptions; ClipRect: PRect = nil): Boolean;

var
  DeltaX: Integer;
  DeltaY: Integer;
  DWPStructure: HDWP;
  I: Integer;
  P: TPoint;
  R: TRect;

begin
  
  if Value.X < (ClientWidth - Integer(FRangeX)) then
    Value.X := ClientWidth - Integer(FRangeX);
  if Value.X > 0 then
    Value.X := 0;
  DeltaX := Value.X - FOffsetX;
  if UseRightToLeftAlignment then
    DeltaX := -DeltaX;
  if Value.Y < (ClientHeight - Integer(FRangeY)) then
    Value.Y := ClientHeight - Integer(FRangeY);
  if Value.Y > 0 then
    Value.Y := 0;
  DeltaY := Value.Y - FOffsetY;

  Result := (DeltaX <> 0) or (DeltaY <> 0);
  if Result then
  begin
    FOffsetX := Value.X;
    FOffsetY := Value.Y;
    Result := True;

    Application.CancelHint;
    if FUpdateCount = 0 then
    begin
      
      if tsVCLDragging in FStates then
        ImageList_DragShowNolock(False);

      if (suoScrollClientArea in Options) and not (tsToggling in FStates) then
      begin
        
        if (toShowBackground in FOptions.FPaintOptions) and (FBackground.Graphic is TBitmap) then
        begin
          
          DWPStructure := BeginDeferWindowPos(ControlCount);
          for I := 0 to ControlCount - 1 do
            if Controls[I] is TWinControl then
            begin
              with Controls[I] as TWinControl do
                DWPStructure := DeferWindowPos(DWPStructure, Handle, 0, Left + DeltaX, Top + DeltaY, 0, 0,
                  SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOSIZE);
              if DWPStructure = 0 then
                Break;
            end;
          if DWPStructure <> 0 then
            EndDeferWindowPos(DWPStructure);
          InvalidateRect(Handle, nil, False);
        end
        else
        begin
          if (DeltaX <> 0) and (Header.Columns.GetVisibleFixedWidth > 0) then
          begin
            
            R := ClientRect;
            R.Left := Header.Columns.GetVisibleFixedWidth;

            ScrollWindow(Handle, DeltaX, 0, @R, @R);
            if DeltaY <> 0 then
              ScrollWindow(Handle, 0, DeltaY, ClipRect, ClipRect);
          end
          else
            ScrollWindow(Handle, DeltaX, DeltaY, ClipRect, ClipRect);
        end;
      end;

      if suoUpdateNCArea in Options then
      begin
        if DeltaX <> 0 then
        begin
          if (suoRepaintHeader in Options) and (hoVisible in FHeader.FOptions) then
            FHeader.Invalidate(nil);
          if not (tsSizing in FStates) and (FScrollBarOptions.ScrollBars in [{$if CompilerVersion >=24}System.UITypes.TScrollStyle.{$ifend}ssHorizontal, {$if CompilerVersion >=24}System.UITypes.TScrollStyle.{$ifend}ssBoth]) then
            UpdateHorizontalScrollBar(suoRepaintScrollbars in Options);
        end;

        if (DeltaY <> 0) and ([tsThumbTracking, tsSizing] * FStates = []) then
        begin
          UpdateVerticalScrollBar(suoRepaintScrollbars in Options);
          if not (FHeader.UseColumns or IsMouseSelecting) and
            (FScrollBarOptions.ScrollBars in [{$if CompilerVersion >=24}System.UITypes.TScrollStyle.{$ifend}ssHorizontal, {$if CompilerVersion >=24}System.UITypes.TScrollStyle.{$ifend}ssBoth]) then
            UpdateHorizontalScrollBar(suoRepaintScrollbars in Options);
        end;
      end;

      if tsVCLDragging in FStates then
        ImageList_DragShowNolock(True);
    end;
    
    GetCursorPos(P);
    P := ScreenToClient(P);
    if PtInRect(ClientRect, P) then
      HandleHotTrack(P.X, P.Y);

    DoScroll(DeltaX, DeltaY);
  end;
end;

procedure TBaseVirtualTree.DoShowScrollbar(Bar: Integer; Show: Boolean);

begin
  ShowScrollBar(Handle, Bar, Show);
  if Assigned(FOnShowScrollbar) then
    FOnShowScrollbar(Self, Bar, Show);
end;

procedure TBaseVirtualTree.DoStartDrag(var DragObject: TDragObject);

begin
  inherited;
  
  if Assigned(DragObject) then
    DoStateChange([tsUserDragObject]);
end;

procedure TBaseVirtualTree.DoStartOperation(OperationKind: TVTOperationKind);

begin
  if Assigned(FOnStartOperation) then
    FOnStartOperation(Self, OperationKind);
end;

procedure TBaseVirtualTree.DoStateChange(Enter: TVirtualTreeStates; Leave: TVirtualTreeStates = []);

var
  ActualEnter,
  ActualLeave: TVirtualTreeStates;

begin
  if Assigned(FOnStateChange) then
  begin
    ActualEnter := Enter - FStates;
    ActualLeave := FStates * Leave;
    if (ActualEnter + ActualLeave) <> [] then
      FOnStateChange(Self, Enter, Leave);
  end;
  FStates := FStates + Enter - Leave;
end;

procedure TBaseVirtualTree.DoStructureChange(Node: PVirtualNode; Reason: TChangeReason);

begin
  StopTimer(StructureChangeTimer);
  if Assigned(FOnStructureChange) then
    FOnStructureChange(Self, Node, Reason);
  
  DoStateChange([], [tsStructureChangePending]);
  FLastStructureChangeNode := nil;
  FLastStructureChangeReason := crIgnore;
end;

procedure TBaseVirtualTree.DoTimerScroll;

var
  P,
  ClientP: TPoint;
  InRect,
  Panning: Boolean;
  R,
  ClipRect: TRect;
  DeltaX,
  DeltaY: Integer;

begin
  GetCursorPos(P);
  R := ClientRect;
  ClipRect := R;
  MapWindowPoints(Handle, 0, R, 2);
  InRect := PtInRect(R, P);
  ClientP := ScreenToClient(P);
  Panning := [tsWheelPanning, tsWheelScrolling] * FStates <> [];

  if IsMouseSelecting or InRect or Panning then
  begin
    DeltaX := 0;
    DeltaY := 0;
    if sdUp in FScrollDirections then
    begin
      if Panning then
        DeltaY := FLastClickPos.Y - ClientP.Y - 8
      else
        if InRect then
          DeltaY := Min(FScrollBarOptions.FIncrementY, ClientHeight)
        else
          DeltaY := Min(FScrollBarOptions.FIncrementY, ClientHeight) * Abs(R.Top - P.Y);
      if FOffsetY = 0 then
        Exclude(FScrollDirections, sdUp);
    end;

    if sdDown in FScrollDirections then
    begin
      if Panning then
        DeltaY := FLastClickPos.Y - ClientP.Y + 8
      else
        if InRect then
          DeltaY := -Min(FScrollBarOptions.FIncrementY, ClientHeight)
        else
          DeltaY := -Min(FScrollBarOptions.FIncrementY, ClientHeight) * Abs(P.Y - R.Bottom);
      if (ClientHeight - FOffsetY) = Integer(FRangeY) then
        Exclude(FScrollDirections, sdDown);
    end;

    if sdLeft in FScrollDirections then
    begin
      if Panning then
        DeltaX := FLastClickPos.X - ClientP.X - 8
      else
        if InRect then
          DeltaX := FScrollBarOptions.FIncrementX
        else
          DeltaX := FScrollBarOptions.FIncrementX * Abs(R.Left - P.X);
      if FEffectiveOffsetX = 0 then
        Exclude(FScrollDirections, sdleft);
    end;

    if sdRight in FScrollDirections then
    begin
      if Panning then
        DeltaX := FLastClickPos.X - ClientP.X + 8
      else
        if InRect then
          DeltaX := -FScrollBarOptions.FIncrementX
        else
          DeltaX := -FScrollBarOptions.FIncrementX * Abs(P.X - R.Right);

      if (ClientWidth + FEffectiveOffsetX) = Integer(FRangeX) then
        Exclude(FScrollDirections, sdRight);
    end;

    if UseRightToLeftAlignment then
      DeltaX := - DeltaX;

    if IsMouseSelecting then
    begin
      
      OffsetRect(ClipRect, DeltaX, DeltaY);
      DoSetOffsetXY(Point(FOffsetX + DeltaX, FOffsetY + DeltaY), DefaultScrollUpdateFlags, @ClipRect);
      
      if CalculateSelectionRect(ClientP.X, ClientP.Y) and HandleDrawSelection(ClientP.X, ClientP.Y) then
        InvalidateRect(Handle, nil, False)
      else
      begin
        
        OffsetRect(ClipRect, DeltaX, DeltaY);
        SubtractRect(ClipRect, ClientRect, ClipRect);
        InvalidateRect(Handle, @ClipRect, False);
        
        UnionRect(ClipRect, OrderRect(FNewSelRect), OrderRect(FLastSelRect));
        OffsetRect(ClipRect, FOffsetX, FOffsetY);
        InvalidateRect(Handle, @ClipRect, False);
      end;
    end
    else
    begin
      
      if ((FDragManager = nil) or not DragManager.IsDropTarget) and ((DeltaX <> 0) or (DeltaY <> 0)) then
        DoSetOffsetXY(Point(FOffsetX + DeltaX, FOffsetY + DeltaY), DefaultScrollUpdateFlags, nil);
    end;
    UpdateWindow(Handle);

    if (FScrollDirections = []) and ([tsWheelPanning, tsWheelScrolling] * FStates = []) then
    begin
      StopTimer(ScrollTimer);
      DoStateChange([], [tsScrollPending, tsScrolling]);
    end;
  end;
end;

procedure TBaseVirtualTree.DoUpdating(State: TVTUpdateState);

begin
  if Assigned(FOnUpdating) then
    FOnUpdating(Self, State);
end;

function TBaseVirtualTree.DoValidateCache: Boolean;

var
  EntryCount,
  CurrentTop,
  Index: Cardinal;
  CurrentNode,
  Temp: PVirtualNode;

begin
  EntryCount := 0;
  if not (tsStopValidation in FStates) then
  begin
    if FStartIndex = 0 then
      FPositionCache := nil;

    EntryCount := CalculateCacheEntryCount;
    SetLength(FPositionCache, EntryCount);
    if FStartIndex > EntryCount then
      FStartIndex := EntryCount;
    
    if (FStartIndex > 0) and Assigned(FPositionCache[FStartIndex - 1].Node) then
    begin
      
      Index := FStartIndex - 1;
      
      CurrentTop := FPositionCache[Index].AbsoluteTop;
      
      CurrentNode := FPositionCache[Index].Node;
    end
    else
    begin
      
      Index := 0;
      
      CurrentTop := 0;
      
      CurrentNode := GetFirstVisibleNoInit(nil, True);
    end;
    
    EntryCount := 0;
    if Assigned(CurrentNode) then
    begin
      while not (tsStopValidation in FStates) do
      begin
        
        if (Integer(Index) > Length(FPositionCache)) then    
          Break;                                             
        if (EntryCount mod CacheThreshold) = 0 then
        begin
          
          with FPositionCache[Index] do
          begin
            Node := CurrentNode;
            AbsoluteTop := CurrentTop;
          end;
          Inc(Index);
        end;

        Inc(CurrentTop, NodeHeight[CurrentNode]);
        
        Temp := GetNextVisibleNoInit(CurrentNode, True);
        
        if (Temp = nil) then       
          Break;                   

        CurrentNode := Temp;
        Inc(EntryCount);
      end;
    end;
    
    if not (tsStopValidation in FStates) and (Integer(Index) <= High(FPositionCache)) then
    begin
      SetLength(FPositionCache, Index + 1);
      with FPositionCache[Index] do
      begin
        Node := CurrentNode;
        AbsoluteTop := CurrentTop;
      end;
    end;
  end;

  Result := (EntryCount > 0) and not (tsStopValidation in FStates);
  
  if Result and (toVariableNodeHeight in FOptions.FMiscOptions) then begin
    UpdateScrollbars(True);
  end;
end;

procedure TBaseVirtualTree.DragAndDrop(AllowedEffects: Dword; DataObject: IDataObject; var DragEffect: LongInt);
{$IF CompilerVersion >= 22}
var
  lDragEffect: DWord; 
{$ifend}
begin
  {$IF CompilerVersion >= 22}
  if IsWinVistaOrAbove then begin
    lDragEffect := DWord(DragEffect);
    SHDoDragDrop(Self.Handle, DataObject, nil, AllowedEffects, lDragEffect); 
    DragEffect := LongInt(lDragEffect);
  end
  else
  {$ifend}
  ActiveX.DoDragDrop(DataObject, DragManager as IDropSource, AllowedEffects, DragEffect);
 end;

procedure TBaseVirtualTree.DragCanceled;

begin
  inherited;

  DragFinished;
end;

function TBaseVirtualTree.DragDrop(const DataObject: IDataObject; KeyState: Integer; Pt: TPoint;
  var Effect: Integer): HResult;

var
  Shift: TShiftState;
  EnumFormat: IEnumFormatEtc;
  Fetched: Integer;
  OLEFormat: TFormatEtc;
  Formats: TFormatArray;

begin
  StopTimer(ExpandTimer);
  StopTimer(ScrollTimer);
  DoStateChange([], [tsScrollPending, tsScrolling]);
  Formats := nil;
  
  Result := DragOver(DragManager.DragSource, KeyState, dsDragMove, Pt, Effect);
  try
    if (Result <>  NOERROR) or ((Effect and not DROPEFFECT_SCROLL) = DROPEFFECT_NONE) then
      Result := E_FAIL
    else
    begin
      try
        Shift := KeysToShiftState(KeyState);
        if tsLeftButtonDown in FStates then
          Include(Shift, ssLeft);
        if tsMiddleButtonDown in FStates then
          Include(Shift, ssMiddle);
        if tsRightButtonDown in FStates then
          Include(Shift, ssRight);
        Pt := ScreenToClient(Pt);
        
        Result := DataObject.EnumFormatEtc(DATADIR_GET, EnumFormat);
        if Failed(Result) then
          Abort;
        Result := EnumFormat.Reset;
        if Failed(Result) then
          Abort;
        
        while EnumFormat.Next(1, OLEFormat, @Fetched) = S_OK do
        begin
          SetLength(Formats, Length(Formats) + 1);
          Formats[High(Formats)] := OLEFormat.cfFormat;
        end;
        DoDragDrop(DragManager.DragSource, DataObject, Formats, Shift, Pt, Effect, FLastDropMode);
      except
        
        Application.HandleException(Self);
        Result := E_UNEXPECTED;
      end;
    end;
  finally
    if Assigned(FDropTargetNode) then
    begin
      InvalidateNode(FDropTargetNode);
      FDropTargetNode := nil;
    end;
  end;
end;

function TBaseVirtualTree.DragEnter(KeyState: Integer; Pt: TPoint; var Effect: Integer): HResult;

var
  Shift: TShiftState;
  Accept: Boolean;
  R: TRect;
  HitInfo: THitInfo;

begin
  try
    
    FDragScrollStart := 0;

    Shift := KeysToShiftState(KeyState);
    if tsLeftButtonDown in FStates then
      Include(Shift, ssLeft);
    if tsMiddleButtonDown in FStates then
      Include(Shift, ssMiddle);
    if tsRightButtonDown in FStates then
      Include(Shift, ssRight);
    Pt := ScreenToClient(Pt);
    Effect := SuggestDropEffect(DragManager.DragSource, Shift, Pt, Effect);
    Accept := DoDragOver(DragManager.DragSource, Shift, dsDragEnter, Pt, FLastDropMode, Effect);
    if not Accept then
      Effect := DROPEFFECT_NONE
    else
    begin
      
      GetHitTestInfoAt(Pt.X, Pt.Y, True, HitInfo);
      if Assigned(HitInfo.HitNode) then
      begin
        FDropTargetNode := HitInfo.HitNode;
        R := GetDisplayRect(HitInfo.HitNode, FHeader.MainColumn, False);
        if (hiOnItemLabel in HitInfo.HitPositions) or ((hiOnItem in HitInfo.HitPositions) and
          ((toFullRowDrag in FOptions.FMiscOptions) or (toFullRowSelect in FOptions.FSelectionOptions)))then
          FLastDropMode := dmOnNode
        else
          if ((R.Top + R.Bottom) div 2) > Pt.Y then
            FLastDropMode := dmAbove
          else
            FLastDropMode := dmBelow;
      end
      else
        FLastDropMode := dmNowhere;
    end;
    
    if not DragManager.DropTargetHelperSupported and Assigned(DragManager.DragSource) then
      DragManager.DragSource.FDragImage.ShowDragImage;
    Result :=  NOERROR;
  except
    Result := E_UNEXPECTED;
  end;
end;

procedure TBaseVirtualTree.DragFinished;

var
  P: TPoint;

begin
  if [tsOLEDragging, tsVCLDragPending, tsVCLDragging, tsVCLDragFinished] * FStates = [] then
    Exit;

  DoStateChange([], [tsVCLDragPending, tsVCLDragging, tsUserDragObject, tsVCLDragFinished]);

  GetCursorPos(P);
  P := ScreenToClient(P);
  if tsRightButtonDown in FStates then
    Perform(WM_RBUTTONUP, 0, LPARAM(Longint(PointToSmallPoint(P))))
  else
    if tsMiddleButtonDown in FStates then
      Perform(WM_MBUTTONUP, 0, LPARAM(Longint(PointToSmallPoint(P))))
    else
      Perform(WM_LBUTTONUP, 0, LPARAM(Longint(PointToSmallPoint(P))));
end;

procedure TBaseVirtualTree.DragLeave;

var
  Effect: Integer;

begin
  StopTimer(ExpandTimer);

  if not DragManager.DropTargetHelperSupported and Assigned(DragManager.DragSource) then
    DragManager.DragSource.FDragImage.HideDragImage;

  if Assigned(FDropTargetNode) then
  begin
    InvalidateNode(FDropTargetNode);
    FDropTargetNode := nil;
  end;
  UpdateWindow(Handle);

  Effect := 0;
  DoDragOver(nil, [], dsDragLeave, Point(0, 0), FLastDropMode, Effect);
end;

function TBaseVirtualTree.DragOver(Source: TObject; KeyState: Integer; DragState: TDragState; Pt: TPoint;
  var Effect: LongInt): HResult;

var
  Shift: TShiftState;
  Accept,
  DragImageWillMove,
  WindowScrolled: Boolean;
  OldR, R: TRect;
  NewDropMode: TDropMode;
  HitInfo: THitInfo;
  DragPos: TPoint;
  Tree: TBaseVirtualTree;
  LastNode: PVirtualNode;
  DeltaX,
  DeltaY: Integer;
  ScrollOptions: TScrollUpdateOptions;

begin
  if not DragManager.DropTargetHelperSupported and (Source is TBaseVirtualTree) then
  begin
    Tree := Source as TBaseVirtualTree;
    ScrollOptions := [suoUpdateNCArea];
  end
  else
  begin
    Tree := nil;
    ScrollOptions := DefaultScrollUpdateFlags;
  end;

  try
    DragPos := Pt;
    Pt := ScreenToClient(Pt);
    
    FScrollDirections := DetermineScrollDirections(Pt.X, Pt.Y);
    DeltaX := 0;
    DeltaY := 0;
    if FScrollDirections <> [] then
    begin
      
      if sdUp in FScrollDirections then
      begin
        DeltaY := Min(FScrollBarOptions.FIncrementY, ClientHeight);
        if FOffsetY = 0 then
          Exclude(FScrollDirections, sdUp);
      end;
      if sdDown in FScrollDirections then
      begin
        DeltaY := -Min(FScrollBarOptions.FIncrementY, ClientHeight);
        if (ClientHeight - FOffsetY) = Integer(FRangeY) then
          Exclude(FScrollDirections, sdDown);
      end;
      if sdLeft in FScrollDirections then
      begin
        DeltaX := FScrollBarOptions.FIncrementX;
        if FEffectiveOffsetX = 0 then
          Exclude(FScrollDirections, sdleft);
      end;
      if sdRight in FScrollDirections then
      begin
        DeltaX := -FScrollBarOptions.FIncrementX;
        if (ClientWidth + FEffectiveOffsetX) = Integer(FRangeX) then
          Exclude(FScrollDirections, sdRight);
      end;
      WindowScrolled := DoSetOffsetXY(Point(FOffsetX + DeltaX, FOffsetY + DeltaY), ScrollOptions, nil);
    end
    else
      WindowScrolled := False;
    
    Shift := KeysToShiftState(KeyState);
    if tsLeftButtonDown in FStates then
      Include(Shift, ssLeft);
    if tsMiddleButtonDown in FStates then
      Include(Shift, ssMiddle);
    if tsRightButtonDown in FStates then
      Include(Shift, ssRight);
    GetHitTestInfoAt(Pt.X, Pt.Y, True, HitInfo);

    if Assigned(HitInfo.HitNode) then
      R := GetDisplayRect(HitInfo.HitNode, NoColumn, False)
    else
      R := Rect(0, 0, 0, 0);
    NewDropMode := DetermineDropMode(Pt, HitInfo, R);

    if Assigned(Tree) then
      DragImageWillMove := Tree.FDragImage.WillMove(DragPos)
    else
      DragImageWillMove := False;

    if (HitInfo.HitNode <> FDropTargetNode) or (FLastDropMode <> NewDropMode) then
    begin
      
      FLastDropMode := NewDropMode;
      if HitInfo.HitNode <> FDropTargetNode then
      begin
        StopTimer(ExpandTimer);
        
        LastNode := FDropTargetNode;
        FDropTargetNode := HitInfo.HitNode;
        
        if FFocusedColumn <= NoColumn then
          FFocusedColumn := FHeader.MainColumn;

        if Assigned(LastNode) and Assigned(FDropTargetNode) then
        begin
          
          OldR := GetDisplayRect(LastNode, NoColumn, False);
          UnionRect(R, R, OldR);
          if Assigned(Tree) then
          begin
            if WindowScrolled then
              UpdateWindowAndDragImage(Tree, ClientRect, True, not DragImageWillMove)
            else
              UpdateWindowAndDragImage(Tree, R, False, not DragImageWillMove);
          end
          else
            InvalidateRect(Handle, @R, False);
        end
        else
        begin
          if Assigned(LastNode) then
          begin
            
            OldR := GetDisplayRect(LastNode, NoColumn, False);
            if Assigned(Tree) then
            begin
              if WindowScrolled then
                UpdateWindowAndDragImage(Tree, ClientRect, WindowScrolled, not DragImageWillMove)
              else
                UpdateWindowAndDragImage(Tree, OldR, False, not DragImageWillMove);
            end
            else
              InvalidateRect(Handle, @OldR, False);
          end
          else
          begin
            if Assigned(Tree) then
            begin
              if WindowScrolled then
                UpdateWindowAndDragImage(Tree, ClientRect, WindowScrolled, not DragImageWillMove)
              else
                UpdateWindowAndDragImage(Tree, R, False, not DragImageWillMove);
            end
            else
              InvalidateRect(Handle, @R, False);
          end;
        end;
        
        if (toAutoDropExpand in FOptions.FAutoOptions) and Assigned(FDropTargetNode) and
          (vsHasChildren in FDropTargetNode.States) then
          SetTimer(Handle, ExpandTimer, FAutoExpandDelay, nil);
      end
      else
      begin
        
        if Assigned(Tree) then
        begin
          if WindowScrolled then
            UpdateWindowAndDragImage(Tree, ClientRect, WindowScrolled, not DragImageWillMove)
          else
            UpdateWindowAndDragImage(Tree, R, False, not DragImageWillMove);
        end
        else
          InvalidateRect(Handle, @R, False);
      end;
    end
    else
    begin
      
      if Assigned(Tree) and ((DeltaX <> 0) or (DeltaY <> 0)) then
        UpdateWindowAndDragImage(Tree, ClientRect, WindowScrolled, not DragImageWillMove);
    end;

    Update;

    if Assigned(Tree) and DragImageWillMove then
      Tree.FDragImage.DragTo(DragPos, False);

    Effect := SuggestDropEffect(Source, Shift, Pt, Effect);
    Accept := DoDragOver(Source, Shift, DragState, Pt, FLastDropMode, Effect);
    if not Accept then
      Effect := DROPEFFECT_NONE;
    if WindowScrolled then
      Effect := Effect or Integer(DROPEFFECT_SCROLL);
    Result :=  NOERROR;
  except
    Result := E_UNEXPECTED;
  end;
end;

procedure TBaseVirtualTree.DrawDottedHLine(const PaintInfo: TVTPaintInfo; Left, Right, Top: Integer);

var
  R: TRect;

begin
  with PaintInfo, Canvas do
  begin
    Brush.Color := FColors.BackGroundColor;
    R := Rect(Min(Left, Right), Top, Max(Left, Right) + 1, Top + 1);
    Windows.FillRect(Handle, R, FDottedBrush);
  end;
end;

procedure TBaseVirtualTree.DrawDottedVLine(const PaintInfo: TVTPaintInfo; Top, Bottom, Left: Integer);

var
  R: TRect;

begin
  with PaintInfo, Canvas do
  begin
    Brush.Color := FColors.BackGroundColor;
    R := Rect(Left, Min(Top, Bottom), Left + 1, Max(Top, Bottom) + 1);
    Windows.FillRect(Handle, R, FDottedBrush);
  end;
end;

procedure TBaseVirtualTree.EndOperation(OperationKind: TVTOperationKind);

begin
  Assert(FOperationCount > 0, 'EndOperation must not be called when no operation in progress.');
  Dec(FOperationCount);
  DoEndOperation(OperationKind);
end;

procedure TBaseVirtualTree.EnsureNodeFocused();
begin
  if FocusedNode = nil then
    FocusedNode := Self.GetFirstVisible();
end;

function TBaseVirtualTree.FindNodeInSelection(P: PVirtualNode; var Index: Integer; LowBound,
  HighBound: Integer): Boolean;

var
  L, H,
  I: Integer;

begin
  Result := False;
  L := 0;
  if LowBound >= 0 then
    L := LowBound;
  H := FSelectionCount - 1;
  if HighBound >= 0 then
    H := HighBound;
  while L <= H do
  begin
    I := (L + H) shr 1;
    if PAnsiChar(FSelection[I]) < PAnsiChar(P) then
      L := I + 1
    else
    begin
      H := I - 1;
      if FSelection[I] = P then
      begin
        Result := True;
        L := I;
      end;
    end;
  end;
  Index := L;
end;

procedure TBaseVirtualTree.FinishChunkHeader(Stream: TStream; StartPos, EndPos: Integer);

var
  Size: Integer;

begin
  
  Stream.Position := StartPos + SizeOf(Size);
  
  Size := EndPos - StartPos - SizeOf(TChunkHeader);
  
  Stream.Write(Size, SizeOf(Size));
  
  Stream.Position := EndPos;
end;

procedure TBaseVirtualTree.FontChanged(AFont: TObject);

begin
  FFontChanged := True;
  if Assigned(FOldFontChange) then
    FOldFontChange(AFont);
end;

function TBaseVirtualTree.GetBorderDimensions: TSize;

var
  Styles: Integer;

begin
  Result.cx := 0;
  Result.cy := 0;

  Styles := GetWindowLong(Handle, GWL_STYLE);
  if (Styles and WS_BORDER) <> 0 then
  begin
    Dec(Result.cx);
    Dec(Result.cy);
  end;
  if (Styles and WS_THICKFRAME) <> 0 then
  begin
    Dec(Result.cx, GetSystemMetrics(SM_CXFIXEDFRAME));
    Dec(Result.cy, GetSystemMetrics(SM_CYFIXEDFRAME));
  end;
  Styles := GetWindowLong(Handle, GWL_EXSTYLE);
  if (Styles and WS_EX_CLIENTEDGE) <> 0 then
  begin
    Dec(Result.cx, GetSystemMetrics(SM_CXEDGE));
    Dec(Result.cy, GetSystemMetrics(SM_CYEDGE));
  end;
end;

function TBaseVirtualTree.GetCheckImage(Node: PVirtualNode; ImgCheckType: TCheckType = ctNone; ImgCheckState:
  TCheckState = csUncheckedNormal; ImgEnabled: Boolean = True): Integer;

const
  
  CheckStateToCheckImage: array[ctCheckBox..ctButton, csUncheckedNormal..csMixedPressed, Boolean, Boolean] of Integer = (
    
    (
      
      ((ckCheckUncheckedDisabled, ckCheckUncheckedDisabled), (ckCheckUncheckedNormal, ckCheckUncheckedHot)),
      
      ((ckCheckUncheckedDisabled, ckCheckUncheckedDisabled), (ckCheckUncheckedPressed, ckCheckUncheckedPressed)),
      
      ((ckCheckCheckedDisabled, ckCheckCheckedDisabled), (ckCheckCheckedNormal, ckCheckCheckedHot)),
      
      ((ckCheckCheckedDisabled, ckCheckCheckedDisabled), (ckCheckCheckedPressed, ckCheckCheckedPressed)),
      
      ((ckCheckMixedDisabled, ckCheckMixedDisabled), (ckCheckMixedNormal, ckCheckMixedHot)),
      
      ((ckCheckMixedDisabled, ckCheckMixedDisabled), (ckCheckMixedPressed, ckCheckMixedPressed))
    ),
    
    (
      
      ((ckRadioUncheckedDisabled, ckRadioUncheckedDisabled), (ckRadioUncheckedNormal, ckRadioUncheckedHot)),
      
      ((ckRadioUncheckedDisabled, ckRadioUncheckedDisabled), (ckRadioUncheckedPressed, ckRadioUncheckedPressed)),
      
      ((ckRadioCheckedDisabled, ckRadioCheckedDisabled), (ckRadioCheckedNormal, ckRadioCheckedHot)),
      
      ((ckRadioCheckedDisabled, ckRadioCheckedDisabled), (ckRadioCheckedPressed, ckRadioCheckedPressed)),
      
      ((ckCheckMixedDisabled, ckCheckMixedDisabled), (ckCheckMixedNormal, ckCheckMixedHot)),
      
      ((ckCheckMixedDisabled, ckCheckMixedDisabled), (ckCheckMixedPressed, ckCheckMixedPressed))
    ),
    
    (
      
      ((ckButtonDisabled, ckButtonDisabled), (ckButtonNormal, ckButtonHot)),
      
      ((ckButtonDisabled, ckButtonDisabled), (ckButtonPressed, ckButtonPressed)),
      
      ((ckButtonDisabled, ckButtonDisabled), (ckButtonNormal, ckButtonHot)),
      
      ((ckButtonDisabled, ckButtonDisabled), (ckButtonPressed, ckButtonPressed)),
      
      ((ckCheckMixedDisabled, ckCheckMixedDisabled), (ckCheckMixedNormal, ckCheckMixedHot)),
      
      ((ckCheckMixedDisabled, ckCheckMixedDisabled), (ckCheckMixedPressed, ckCheckMixedPressed))
    )
  );

var
  IsHot: Boolean;

begin
  if Assigned(Node) then
  begin
    ImgCheckType := Node.CheckType;
    ImgCheckState := Node.CheckState;
    ImgEnabled := not (vsDisabled in Node.States) and Enabled;
    IsHot := Node = FCurrentHotNode;
  end
  else
    IsHot := False;

  if ImgCheckType = ctTriStateCheckBox then
    ImgCheckType := ctCheckBox;

  if ImgCheckType = ctNone then
    Result := -1
  else
    Result := CheckStateToCheckImage[ImgCheckType, ImgCheckState, ImgEnabled, IsHot];
end;

class function TBaseVirtualTree.GetCheckImageListFor(Kind: TCheckImageKind): TCustomImageList;

begin
  case Kind of
    ckDarkCheck:
      Result := DarkCheckImages;
    ckLightTick:
      Result := LightTickImages;
    ckDarkTick:
      Result := DarkTickImages;
    ckLightCheck:
      Result := LightCheckImages;
    ckFlat:
      Result := FlatImages;
    ckXP:
      Result := XPImages;
    ckSystemDefault:
      Result := SystemCheckImages;
    ckSystemFlat:
      Result := SystemFlatCheckImages;
    else
      Result := nil;
  end;
end;

function TBaseVirtualTree.GetColumnClass: TVirtualTreeColumnClass;

begin
  Result := TVirtualTreeColumn;
end;

function TBaseVirtualTree.GetHeaderClass: TVTHeaderClass;

begin
  Result := TVTHeader;
end;

function TBaseVirtualTree.GetHintWindowClass: THintWindowClass;

begin
  Result := TVirtualTreeHintWindow;
end;

procedure TBaseVirtualTree.GetImageIndex(var Info: TVTPaintInfo; Kind: TVTImageKind; InfoIndex: TVTImageInfoIndex;
  DefaultImages: TCustomImageList);

var
  CustomImages: TCustomImageList;

begin
  with Info do
  begin
    ImageInfo[InfoIndex].Index := -1;
    ImageInfo[InfoIndex].Ghosted := False;

    CustomImages := DoGetImageIndex(Node, Kind, Column, ImageInfo[InfoIndex].Ghosted, ImageInfo[InfoIndex].Index);
    if Assigned(CustomImages) then
      ImageInfo[InfoIndex].Images := CustomImages
    else
      ImageInfo[InfoIndex].Images := DefaultImages;
  end;
end;

function TBaseVirtualTree.GetNodeImageSize(Node: PVirtualNode): TSize;
  
begin
  if Assigned(fImages) then begin
    Result.cx := fImages.Width;
    Result.cy := FImages.Height;
  end
  else begin
    Result.cx := 0;
    Result.cy := 0;
  end;
end;

function TBaseVirtualTree.GetMaxRightExtend: Cardinal;

var
  Node,
  NextNode: PVirtualNode;
  TopPosition: Integer;
  NodeLeft,
  CurrentWidth: Integer;
  WithCheck: Boolean;
  CheckOffset: Integer;

begin
  Node := GetNodeAt(0, 0, True, TopPosition);
  Result := 0;
  if toShowRoot in FOptions.FPaintOptions then
    NodeLeft := (GetNodeLevel(Node) + 1) * FIndent
  else
    NodeLeft := GetNodeLevel(Node) * FIndent;

  if Assigned(FStateImages) then
    Inc(NodeLeft, FStateImages.Width + 2);
  if Assigned(FImages) then
    Inc(NodeLeft, FImages.Width + 2);
  WithCheck := (toCheckSupport in FOptions.FMiscOptions) and Assigned(FCheckImages);
  if WithCheck then
    CheckOffset := FCheckImages.Width + 2
  else
    CheckOffset := 0;

  while Assigned(Node) do
  begin
    if not (vsInitialized in Node.States) then
      InitNode(Node);

    if WithCheck and (Node.CheckType <> ctNone) then
      Inc(NodeLeft, CheckOffset);
    CurrentWidth := DoGetNodeWidth(Node, NoColumn);
    Inc(CurrentWidth, DoGetNodeExtraWidth(Node, NoColumn));
    if Integer(Result) < (NodeLeft + CurrentWidth) then
      Result := NodeLeft + CurrentWidth;
    Inc(TopPosition, NodeHeight[Node]);
    if TopPosition > Height then
      Break;

    if WithCheck and (Node.CheckType <> ctNone) then
      Dec(NodeLeft, CheckOffset);
    
    NextNode := GetNextVisible(Node, True);
    if NextNode = nil then
      Break;
    Inc(NodeLeft, CountLevelDifference(Node, NextNode) * Integer(FIndent));
    Node := NextNode;
  end;

  Inc(Result, FMargin);
end;

procedure TBaseVirtualTree.GetNativeClipboardFormats(var Formats: TFormatEtcArray);

begin
  InternalClipboardFormats.EnumerateFormats(TVirtualTreeClass(ClassType), Formats, FClipboardFormats);
  
  DoGetUserClipboardFormats(Formats);
end;

function TBaseVirtualTree.GetOperationCanceled;

begin
  Result := FOperationCanceled and (FOperationCount > 0);
end;

function TBaseVirtualTree.GetOptionsClass: TTreeOptionsClass;

begin
  Result := TCustomVirtualTreeOptions;
end;

function TBaseVirtualTree.GetTreeFromDataObject(const DataObject: IDataObject): TBaseVirtualTree;

var
  Medium: TStgMedium;
  Data: PVTReference;

begin
  Result := nil;
  if Assigned(DataObject) then
  begin
    StandardOLEFormat.cfFormat := CF_VTREFERENCE;
    if DataObject.GetData(StandardOLEFormat, Medium) = S_OK then
    begin
      Data := GlobalLock(Medium.hGlobal);
      if Assigned(Data) then
      begin
        if Data.Process = GetCurrentProcessID then
          Result := Data.Tree;
        GlobalUnlock(Medium.hGlobal);
      end;
      ReleaseStgMedium(Medium);
    end;
  end;
end;

procedure TBaseVirtualTree.HandleHotTrack(X, Y: Integer);

var
  HitInfo: THitInfo;
  CheckPositions: THitPositions;
  ButtonIsHit,
  DoInvalidate: Boolean;

begin
  DoInvalidate := False;
  
  GetHitTestInfoAt(X, Y, True, HitInfo);
  
  CheckPositions := [hiOnItemLabel, hiOnItemCheckbox];
  
  if tsUseExplorerTheme in FStates then
    Include(CheckPositions, hiOnItemButtonExact);

  if (CheckPositions * HitInfo.HitPositions = []) and
    (not (toFullRowSelect in FOptions.FSelectionOptions) or (hiNowhere in HitInfo.HitPositions)) then
    HitInfo.HitNode := nil;
  if (HitInfo.HitNode <> FCurrentHotNode) or (HitInfo.HitColumn <> FCurrentHotColumn) then
  begin
    DoInvalidate := (toHotTrack in FOptions.PaintOptions) or (toCheckSupport in FOptions.FMiscOptions);
    DoHotChange(FCurrentHotNode, HitInfo.HitNode);
    if Assigned(FCurrentHotNode) and DoInvalidate then
      InvalidateNode(FCurrentHotNode);
    FCurrentHotNode := HitInfo.HitNode;
    FCurrentHotColumn := HitInfo.HitColumn;
  end;

  ButtonIsHit := (hiOnItemButtonExact in HitInfo.HitPositions) and (toHotTrack in FOptions.FPaintOptions);
  if Assigned(FCurrentHotNode) and ((FHotNodeButtonHit <> ButtonIsHit) or DoInvalidate) then
  begin
    FHotNodeButtonHit := ButtonIsHit and (toHotTrack in FOptions.FPaintOptions);
    InvalidateNode(FCurrentHotNode);
  end
  else
    if not Assigned(FCurrentHotNode) then
      FHotNodeButtonHit := False;
end;

procedure TBaseVirtualTree.HandleIncrementalSearch(CharCode: Word);

var
  Run, Stop: PVirtualNode;
  GetNextNode: TGetNextNodeProc;
  NewSearchText: UnicodeString;
  SingleLetter,
  PreviousSearch: Boolean; 
  SearchDirection: TVTSearchDirection;

  procedure SetupNavigation;

  var
    FindNextNode: Boolean;

  begin
    FindNextNode := (Length(FSearchBuffer) = 0) or (Run = nil) or SingleLetter or PreviousSearch;
    case FIncrementalSearch of
      isVisibleOnly:
        if SearchDirection = sdForward then
        begin
          GetNextNode := GetNextVisible;
          if FindNextNode then
          begin
            if Run = nil then
              Run := GetFirstVisible(nil, True)
            else
            begin
              Run := GetNextVisible(Run, True);
              
              if Run = nil then
                Run := GetFirstVisible(nil, True);
            end;
          end;
        end
        else
        begin
          GetNextNode := GetPreviousVisible;
          if FindNextNode then
          begin
            if Run = nil then
              Run := GetLastVisible(nil, True)
            else
            begin
              Run := GetPreviousVisible(Run, True);
              
              if Run = nil then
                Run := GetLastVisible(nil, True);
            end;
          end;
        end;
      isInitializedOnly:
        if SearchDirection = sdForward then
        begin
          GetNextNode := GetNextNoInit;
          if FindNextNode then
          begin
            if Run = nil then
              Run := GetFirstNoInit
            else
            begin
              Run := GetNextNoInit(Run);
              
              if Run = nil then
                Run := GetFirstNoInit;
            end;
          end;
        end
        else
        begin
          GetNextNode := GetPreviousNoInit;
          if FindNextNode then
          begin
            if Run = nil then
              Run := GetLastNoInit
            else
            begin
              Run := GetPreviousNoInit(Run);
              
              if Run = nil then
                Run := GetLastNoInit;
            end;
          end;
        end;
    else
      
      if SearchDirection = sdForward then
      begin
        GetNextNode := GetNext;
        if FindNextNode then
        begin
          if Run = nil then
            Run := GetFirst
          else
          begin
            Run := GetNext(Run);
            
            if Run = nil then
              Run := GetFirst;
          end;
        end;
      end
      else
      begin
        GetNextNode := GetPrevious;
        if FindNextNode then
        begin
          if Run = nil then
            Run := GetLast
          else
          begin
            Run := GetPrevious(Run);
            
            if Run = nil then
              Run := GetLast;
          end;
        end;
      end;
    end;
  end;

  function CodePageFromLocale(Language: LCID): Integer;

  var
    Buf: array[0..6] of Char;

  begin
    GetLocaleInfo(Language, LOCALE_IDEFAULTANSICODEPAGE, Buf, 6);
    Result := StrToIntDef(Buf, GetACP);
  end;

  function KeyUnicode(C: Char): WideChar;
  
  begin
    {$ifdef UNICODE}
    Result := C;      
    {$ELSE}
    MultiByteToWideChar(CodePageFromLocale(GetKeyboardLayout(0) and $FFFF),
      MB_USEGLYPHCHARS, @C, 1, @Result, 1);
    {$endif}
  end;

var
  FoundMatch: Boolean;
  NewChar: WideChar;

begin
  StopTimer(SearchTimer);

  if FIncrementalSearch <> isNone then
  begin
    if CharCode <> 0 then
    begin
      DoStateChange([tsIncrementalSearching]);
      
      NewChar := KeyUnicode(Char(CharCode));
      PreviousSearch := NewChar = WideChar(VK_BACK);
      
      if not PreviousSearch or (FSearchBuffer <> '') then
      begin
        
        case FSearchStart of
          ssAlwaysStartOver:
            Run := nil;
          ssFocusedNode:
            Run := FFocusedNode;
        else 
          Run := FLastSearchNode;
        end;
        
        if Assigned(Run) then
        begin
          case FIncrementalSearch of
            isInitializedOnly:
              if not (vsInitialized in Run.States) then
                Run := nil;
            isVisibleOnly:
              if not FullyVisible[Run] or IsEffectivelyFiltered[Run] then
                Run := nil;
          end;
        end;
        Stop := Run;
        
        if PreviousSearch then
        begin
          if SearchDirection = sdBackward then
            SearchDirection := sdForward
          else
            SearchDirection := sdBackward
        end
        else
          SearchDirection := FSearchDirection;
        
        SingleLetter := (Length(FSearchBuffer) = 1) and not PreviousSearch and (FSearchBuffer[1] = NewChar);
        
        if SingleLetter and (DoIncrementalSearch(Run, FSearchBuffer + NewChar) = 0) then
          SingleLetter := False;
        SetupNavigation;
        FoundMatch := False;

        if Assigned(Run) then
        begin
          if SingleLetter then
            NewSearchText := FSearchBuffer
          else
            if PreviousSearch then
            begin
              SetLength(FSearchBuffer, Length(FSearchBuffer) - 1);
              NewSearchText := FSearchBuffer;
            end
            else
              NewSearchText := FSearchBuffer + NewChar;

          repeat
            if DoIncrementalSearch(Run, NewSearchText) = 0 then
            begin
              FoundMatch := True;
              Break;
            end;
            
            Run := GetNextNode(Run);
            
            if (Run <> Stop) and (Run = nil) then
              SetupNavigation;
          until Run = Stop;
        end;

        if FoundMatch then
        begin
          ClearSelection;
          FSearchBuffer := NewSearchText;
          FLastSearchNode := Run;
          FocusedNode := Run;
          Selected[Run] := True;
          FLastSearchNode := Run;
        end
        else
          
          if Assigned(Run) and (DoIncrementalSearch(Run, NewSearchText) <> 0) then
            Beep;
      end;
    end;
    
    SetTimer(Handle, SearchTimer, FSearchTimeout, nil);
  end;
end;

procedure TBaseVirtualTree.HandleMouseDblClick(var Message: TWMMouse; const HitInfo: THitInfo);

var
  NewCheckState: TCheckState;
  Node: PVirtualNode;
  MayEdit: Boolean;

begin
  MayEdit := not (tsEditing in FStates) and (toEditOnDblClick in FOptions.FMiscOptions);
  if tsEditPending in FStates then
  begin
    StopTimer(EditTimer);
    DoStateChange([], [tsEditPending]);
  end;

  if not (tsEditing in FStates) or DoEndEdit then
  begin
    if HitInfo.HitColumn = FHeader.FColumns.FClickIndex then
      DoColumnDblClick(HitInfo.HitColumn, KeysToShiftState(Message.Keys));

      if HitInfo.HitNode <> nil then
      DoNodeDblClick(HitInfo);

    Node := nil;
    if (hiOnItem in HitInfo.HitPositions) and (hitInfo.HitColumn > NoColumn) and
       (coFixed in FHeader.FColumns[HitInfo.HitColumn].FOptions) then
    begin
      if hiUpperSplitter in HitInfo.HitPositions then
        Node := GetPreviousVisible(HitInfo.HitNode, True)
      else
        if  hiLowerSplitter in HitInfo.HitPositions then
          Node := HitInfo.HitNode
    end;

    if Assigned(Node) and (Node <> FRoot) and (toNodeHeightDblClickResize in FOptions.FMiscOptions) then
    begin
      if DoNodeHeightDblClickResize(Node, HitInfo.HitColumn, KeysToShiftState(Message.Keys), Point(Message.XPos, Message.YPos)) then
      begin
        SetNodeHeight(Node, FDefaultNodeHeight);
        UpdateWindow(Handle);
        MayEdit := False;
      end;
    end
    else
      if hiOnItemCheckBox in HitInfo.HitPositions then
      begin
        if (FStates * [tsMouseCheckPending, tsKeyCheckPending] = []) and not (vsDisabled in HitInfo.HitNode.States) then
        begin
          with HitInfo.HitNode^ do
            NewCheckState := DetermineNextCheckState(CheckType, CheckState);
          if (ssLeft in KeysToShiftState(Message.Keys)) and DoChecking(HitInfo.HitNode, NewCheckState) then
          begin
            DoStateChange([tsMouseCheckPending]);
            FCheckNode := HitInfo.HitNode;
            FPendingCheckState := NewCheckState;
            FCheckNode.CheckState := PressedState[FCheckNode.CheckState];
            InvalidateNode(HitInfo.HitNode);
            MayEdit := False;
          end;
        end;
      end
      else
      begin
        if hiOnItemButton in HitInfo.HitPositions then
        begin
          ToggleNode(HitInfo.HitNode);
          MayEdit := False;
        end
        else
        begin
          if toToggleOnDblClick in FOptions.FMiscOptions then
          begin
            if ((([hiOnItemButton, hiOnItemLabel, hiOnNormalIcon, hiOnStateIcon] * HitInfo.HitPositions) <> []) or
              ((toFullRowSelect in FOptions.FSelectionOptions) and Assigned(HitInfo.HitNode))) then
            begin
              ToggleNode(HitInfo.HitNode);
              MayEdit := False;
            end;
          end;
        end;
      end;
  end;

  if MayEdit and Assigned(FFocusedNode) and (FFocusedNode = HitInfo.HitNode) and
    (FFocusedColumn = HitInfo.HitColumn) and CanEdit(FFocusedNode, HitInfo.HitColumn) then
  begin
    DoStateChange([tsEditPending]);
    FEditColumn := FFocusedcolumn;
    SetTimer(Handle, EditTimer, FEditDelay, nil);
  end;
end;

procedure TBaseVirtualTree.HandleMouseDown(var Message: TWMMouse; var HitInfo: THitInfo);

var
  LastFocused: PVirtualNode;
  Column: TColumnIndex;
  ShiftState: TShiftState;
  
  AutoDrag,              
  IsLabelHit,            
  IsCellHit,             
  IsAnyHit,              
  IsHeightTracking,      
  MultiSelect,           
  ShiftEmpty,            
  NodeSelected: Boolean; 
  NewColumn: Boolean;    
  NewNode: Boolean;      
  NeedChange: Boolean;   
  CanClear: Boolean;
  NewCheckState: TCheckState;
  AltPressed: Boolean;   
  FullRowDrag: Boolean;  
  NodeRect: TRect;

begin
  if [tsWheelPanning, tsWheelScrolling] * FStates <> [] then
  begin
    StopWheelPanning;
    Exit;
  end;

  if tsEditPending in FStates then
  begin
    StopTimer(EditTimer);
    DoStateChange([], [tsEditPending]);
  end;

  if (tsEditing in FStates) then
    DoEndEdit;
    
    if not Focused and CanFocus then
    begin
      Windows.SetFocus(Handle);
      
      GetHitTestInfoAt(Message.XPos, Message.YPos, True, HitInfo);
    end;
    
    FHeader.FColumns.FClickIndex := HitInfo.HitColumn;
    
    if (hiOnItemLabel in HitInfo.HitPositions) or
      (toFullRowSelect in FOptions.FSelectionOptions) or
      (toGridExtensions in FOptions.FMiscOptions) then
    begin
      NewColumn := FFocusedColumn <> HitInfo.HitColumn;
      if toExtendedFocus in FOptions.FSelectionOptions then
        Column := HitInfo.HitColumn
      else
        Column := FHeader.MainColumn;
    end
    else
    begin
      NewColumn := False;
      Column := FFocusedColumn;
    end;

    if NewColumn and
       (not FHeader.AllowFocus(Column)) then
    begin
      NewColumn := False;
      Column := FFocusedColumn;
    end;

    NewNode := FFocusedNode <> HitInfo.HitNode;
    
    ShiftState := KeysToShiftState(Message.Keys) * [ssShift, ssCtrl, ssAlt];
    if ssAlt in ShiftState then
    begin
      AltPressed := True;
      
      Exclude(ShiftState, ssAlt);
    end
    else
      AltPressed := False;
    
    IsLabelHit := not AltPressed and not (toSimpleDrawSelection in FOptions.FSelectionOptions) and
             ((hiOnItemLabel in HitInfo.HitPositions) or (hiOnNormalIcon in HitInfo.HitPositions));
    IsCellHit := not AltPressed and not IsLabelHit and Assigned(HitInfo.HitNode) and
      ([hiOnItemButton, hiOnItemCheckBox] * HitInfo.HitPositions = []) and
      ((toFullRowSelect in FOptions.FSelectionOptions) or
      ((toGridExtensions in FOptions.FMiscOptions) and (HitInfo.HitColumn > NoColumn)));
    IsAnyHit := IsLabelHit or IsCellHit;
    MultiSelect := toMultiSelect in FOptions.FSelectionOptions;
    ShiftEmpty := ShiftState = [];
    NodeSelected := IsAnyHit and (vsSelected in HitInfo.HitNode.States);
    if MultiSelect then
    begin
      
      FullRowDrag := (toFullRowDrag in FOptions.FMiscOptions) and IsCellHit and
          not (hiNowhere in HitInfo.HitPositions) and
          (NodeSelected or (hiOnItemLabel in HitInfo.HitPositions) or (hiOnNormalIcon in HitInfo.HitPositions))
    end
    else 
      FullRowDrag := toFullRowDrag in FOptions.FMiscOptions;

    IsHeightTracking := (Message.Msg = WM_LBUTTONDOWN) and
                        (hiOnItem in HitInfo.HitPositions) and
                        ([hiUpperSplitter, hiLowerSplitter] * HitInfo.HitPositions <> []);
    
    AutoDrag := ((DragMode = dmAutomatic) or Dragging) and (not IsCellHit or FullRowDrag);
    
    if Assigned(HitInfo.HitNode) and not AutoDrag and (DragMode = dmManual) then
      AutoDrag := DoBeforeDrag(HitInfo.HitNode, Column) and (FullRowDrag or IsLabelHit);
    
    if IsHeightTracking then
    begin
      if hiUpperSplitter in HitInfo.HitPositions then
        FHeightTrackNode := GetPreviousVisible(HitInfo.HitNode, True)
      else
        FHeightTrackNode := HitInfo.HitNode;

      if CanSplitterResizeNode(Point(Message.XPos, Message.YPos), FHeightTrackNode, HitInfo.HitColumn) then
      begin
        FHeightTrackColumn := HitInfo.HitColumn;
        NodeRect := GetDisplayRect(FHeightTrackNode, FHeightTrackColumn, False);
        FHeightTrackPoint := Point(NodeRect.Left, NodeRect.Top);
        DoStateChange([tsNodeHeightTrackPending]);
        Exit;
      end;
    end;
    
    if (hiOnItemButton in HitInfo.HitPositions) and (vsHasChildren in HitInfo.HitNode.States) then
    begin
      ToggleNode(HitInfo.HitNode);
      Exit;
    end;
    
    if hiOnItemCheckBox in HitInfo.HitPositions then
    begin
      if (FStates * [tsMouseCheckPending, tsKeyCheckPending] = []) and not (vsDisabled in HitInfo.HitNode.States) then
      begin
        with HitInfo.HitNode^ do
          NewCheckState := DetermineNextCheckState(CheckType, CheckState);
        if (ssLeft in KeysToShiftState(Message.Keys)) and DoChecking(HitInfo.HitNode, NewCheckState) then
        begin
          DoStateChange([tsMouseCheckPending]);
          FCheckNode := HitInfo.HitNode;
          FPendingCheckState := NewCheckState;
          FCheckNode.CheckState := PressedState[FCheckNode.CheckState];
          InvalidateNode(HitInfo.HitNode);
        end;
      end;
      Exit;
    end;
    
    if (FRoot.ChildCount > 0) and ShiftEmpty or (FSelectionCount = 0) then
      if Assigned(HitInfo.HitNode) then
        FLastSelectionLevel := GetNodeLevel(HitInfo.HitNode)
      else
        FLastSelectionLevel := GetNodeLevel(GetLastVisibleNoInit(nil, True));
    
    if MultiSelect and ShiftEmpty and not (hiOnItemCheckbox in HitInfo.HitPositions) and IsAnyHit and AutoDrag and
      NodeSelected and not FSelectionLocked then
      DoStateChange([tsClearPending]);
    
    with HitInfo, Message do
      CanClear := not AutoDrag and
        (not (tsRightButtonDown in FStates) or not HasPopupMenu(HitNode, HitColumn, Point(XPos, YPos)));
    
    if not (toDisableDrawSelection in FOptions.FSelectionOptions) and not (IsLabelHit or FullRowDrag) and MultiSelect then
    begin
      SetCapture(Handle);
      DoStateChange([tsDrawSelPending]);
      FDrawSelShiftState := ShiftState;
      FNewSelRect := Rect(Message.XPos + FEffectiveOffsetX, Message.YPos - FOffsetY, Message.XPos + FEffectiveOffsetX,
        Message.YPos - FOffsetY);
      FLastSelRect := Rect(0, 0, 0, 0);
    end;

    if not FSelectionLocked and ((not (IsAnyHit or FullRowDrag) and MultiSelect and ShiftEmpty) or
      (IsAnyHit and (not NodeSelected or (NodeSelected and CanClear)) and (ShiftEmpty or not MultiSelect))) then
    begin
      Assert(not (tsClearPending in FStates), 'Pending and direct clearance are mutual exclusive!');
      
      if NodeSelected or (AltPressed and Assigned(HitInfo.HitNode) and (HitInfo.HitColumn = FHeader.MainColumn)) and not (hiNowhere in HitInfo.HitPositions) then
      begin
        NeedChange := FSelectionCount > 1;
        InternalClearSelection;
        InternalAddToSelection(HitInfo.HitNode, True);
        if NeedChange then
        begin
          Invalidate;
          Change(nil);
        end;
      end
      else
        ClearSelection;
    end;
    
    if Focused and
      ((hiOnItemLabel in HitInfo.HitPositions) or ((toGridExtensions in FOptions.FMiscOptions) and
      (hiOnItem in HitInfo.HitPositions))) and NodeSelected and not NewColumn and ShiftEmpty then
    begin
      DoStateChange([tsEditPending]);
    end;

    if not (toDisableDrawSelection in FOptions.FSelectionOptions) and not (IsLabelHit or FullRowDrag) and MultiSelect then
    begin
      
      if not IsCellHit or (hiNowhere in HitInfo.HitPositions) then
        Exit;
    end;
    
    FLastClickPos := Point(Message.XPos, Message.YPos);
    
    if (IsLabelHit or IsCellHit) and
       DoFocusChanging(FFocusedNode, HitInfo.HitNode, FFocusedColumn, Column) then
    begin
      if NewColumn then
      begin
        InvalidateColumn(FFocusedColumn);
        InvalidateColumn(Column);
        FFocusedColumn := Column;
      end;
      if DragKind = dkDock then
      begin
        StopTimer(ScrollTimer);
        DoStateChange([], [tsScrollPending, tsScrolling]);
      end;
      
      LastFocused := FFocusedNode;
      if NewNode then
        DoFocusNode(HitInfo.HitNode, False);

      if MultiSelect and not ShiftEmpty then
        HandleClickSelection(LastFocused, HitInfo.HitNode, ShiftState, AutoDrag)
      else
      begin
        if ShiftEmpty then
          FRangeAnchor := HitInfo.HitNode;
        
        if not NodeSelected then
          AddToSelection(HitInfo.HitNode);
      end;

      if NewNode or NewColumn then
      begin
        ScrollIntoView(FFocusedNode, toCenterScrollIntoView in FOptions.SelectionOptions,
                       not (toDisableAutoscrollOnFocus in FOptions.FAutoOptions) and not (toFullRowSelect in FOptions.SelectionOptions));
        DoFocusChange(FFocusedNode, FFocusedColumn);
      end;
    end;
    
    if AutoDrag and IsAnyHit and (FStates * [tsLeftButtonDown, tsRightButtonDown, tsMiddleButtonDown] <> []) then
      BeginDrag(False);
  end;

procedure TBaseVirtualTree.HandleMouseUp(var Message: TWMMouse; const HitInfo: THitInfo);

var
  ReselectFocusedNode: Boolean;

begin
  ReleaseCapture;

  if not (tsVCLDragPending in FStates) then
  begin
    
    if IsMouseSelecting then
    begin
      DoStateChange([], [tsDrawSelecting, tsDrawSelPending, tsToggleFocusedSelection]);
      Invalidate;
    end;

    if tsClearPending in FStates then
    begin
      ReselectFocusedNode := Assigned(FFocusedNode) and (vsSelected in FFocusedNode.States);
      ClearSelection;
      if ReselectFocusedNode then
        AddToSelection(FFocusedNode);
    end;

    if (tsToggleFocusedSelection in FStates) and (HitInfo.HitNode = FFocusedNode) and Assigned(HitInfo.HitNode) then 
    begin
      if vsSelected in HitInfo.HitNode.States then
        RemoveFromSelection(HitInfo.HitNode)
      else
        AddToSelection(HitInfo.HitNode);
      InvalidateNode(HitInfo.HitNode);
    end;

    DoStateChange([], [tsOLEDragPending, tsOLEDragging, tsClearPending, tsDrawSelPending, tsToggleFocusedSelection,
      tsScrollPending, tsScrolling]);
    StopTimer(ScrollTimer);

    if tsMouseCheckPending in FStates then
    begin
      DoStateChange([], [tsMouseCheckPending]);
     
     if Assigned (FCheckNode) then begin
       
       if (HitInfo.HitNode = FCheckNode) and (hiOnItem in HitInfo.HitPositions) then
          DoCheckClick(FCheckNode, FPendingCheckState)
        else
          FCheckNode.CheckState := UnpressedState[FCheckNode.CheckState];
        InvalidateNode(FCheckNode);
      end;
      FCheckNode := nil;
    end;

    if (FHeader.FColumns.FClickIndex > NoColumn) and (FHeader.FColumns.FClickIndex = HitInfo.HitColumn) then
      DoColumnClick(HitInfo.HitColumn, KeysToShiftState(Message.Keys));

    if HitInfo.HitNode <> nil then
     DoNodeClick(HitInfo);
    
    if tsEditPending in FStates then
    begin
      
      if (HitInfo.HitNode = FFocusedNode) and (hiOnItem in HitInfo.HitPositions) and
         (toEditOnClick in FOptions.FMiscOptions) and CanEdit(FFocusedNode, HitInfo.HitColumn) then
      begin
        FEditColumn := FFocusedColumn;
        SetTimer(Handle, EditTimer, FEditDelay, nil);
      end
      else
        DoStateChange([], [tsEditPending]);
    end;
  end;
end;

function TBaseVirtualTree.HasImage(Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex): Boolean;

var
  Ghosted: Boolean;
  Index: Integer;

begin
  if not (vsInitialized in Node.States) then
    InitNode(Node);

  Index := -1;
  Ghosted := False;
  DoGetImageIndex(Node, Kind, Column, Ghosted, Index);
  Result := Index > -1;
end;

function TBaseVirtualTree.HasPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Pos: TPoint): Boolean;

begin
  Result := Assigned(PopupMenu) or Assigned(DoGetPopupMenu(Node, Column, Pos));
end;

procedure TBaseVirtualTree.InitChildren(Node: PVirtualNode);

var
  Count: Cardinal;

begin
  if Assigned(Node) and (Node <> FRoot) and (vsHasChildren in Node.States) then
  begin
    Count := Node.ChildCount;
    DoInitChildren(Node, Count);
    if Count <> Node.ChildCount then
      SetChildCount(Node, Count);
    if Count = 0 then
      Exclude(Node.States, vsHasChildren);
  end;
end;

procedure TBaseVirtualTree.InitNode(Node: PVirtualNode);

var
  InitStates: TVirtualNodeInitStates;

begin
  with Node^ do
  begin
    InitStates := [];
    if vsInitialized in States then
      Include(InitStates, ivsReInit);
    Include(States, vsInitialized);
    if Parent = FRoot then
      DoInitNode(nil, Node, InitStates)
    else
      DoInitNode(Parent, Node, InitStates);
    if ivsDisabled in InitStates then
      Include(States, vsDisabled);
    if ivsHasChildren in InitStates then
      Include(States, vsHasChildren);
    if ivsSelected in InitStates then
    begin
      FSingletonNodeArray[0] := Node;
      InternalAddToSelection(FSingletonNodeArray, 1, False);
    end;
    if ivsMultiline in InitStates then
      Include(States, vsMultiline);
    if ivsFiltered in InitStates then
    begin
      Include(States, vsFiltered);
      if not (toShowFilteredNodes in FOptions.FPaintOptions) then
      begin
        AdjustTotalHeight(Node, -NodeHeight, True);
        if FullyVisible[Node] then
          Dec(FVisibleCount);
        UpdateScrollBars(True);
      end;
    end;
    
    if (vsExpanded in Node.States) xor (ivsExpanded in InitStates) then
    begin
      
      if ivsExpanded in InitStates then
        ToggleNode(Node)
      else
        
        if vsHasChildren in Node.States then
          InitChildren(Node);
    end;
  end;
end;

procedure TBaseVirtualTree.InternalAddFromStream(Stream: TStream; Version: Integer; Node: PVirtualNode);

var
  Stop: PVirtualNode;
  Index: Integer;
  LastTotalHeight: Cardinal;
  WasFullyVisible: Boolean;

begin
  Assert(Node <> FRoot, 'The root node cannot be loaded from stream.');
  
  LastTotalHeight := Node.TotalHeight;
  WasFullyVisible := FullyVisible[Node] and not IsEffectivelyFiltered[Node];
  
  ReadNode(Stream, Version, Node);
  
  FixupTotalCount(Node);
  AdjustTotalCount(Node.Parent, Node.TotalCount - 1, True); 
  FixupTotalHeight(Node);
  AdjustTotalHeight(Node.Parent, Node.TotalHeight - LastTotalHeight, True);
  
  if not FullyVisible[Node] or IsEffectivelyFiltered[Node] then
  begin
    if WasFullyVisible then
      Dec(FVisibleCount);
  end
  else
    
    Inc(FVisibleCount, CountVisibleChildren(Node));
  
  ClearTempCache;
  if Node = FRoot then
    Stop := nil
  else
    Stop := Node.NextSibling;

  if toMultiSelect in FOptions.FSelectionOptions then
  begin
    
    while Node <> Stop do
    begin
      if (vsSelected in Node.States) and not FindNodeInSelection(Node, Index, 0, High(FSelection)) then
        InternalCacheNode(Node);
      Node := GetNextNoInit(Node);
    end;
    if FTempNodeCount > 0 then
      AddToSelection(FTempNodeCache, FTempNodeCount, True);
    ClearTempCache;
  end
  else 
    while Node <> Stop do
    begin
      Exclude(Node.States, vsSelected);
      Node := GetNextNoInit(Node);
    end;
end;

function TBaseVirtualTree.InternalAddToSelection(Node: PVirtualNode; ForceInsert: Boolean): Boolean;

begin
  Assert(Assigned(Node), 'Node must not be nil!');
  FSingletonNodeArray[0] := Node;
  Result := InternalAddToSelection(FSingletonNodeArray, 1, ForceInsert);
end;

function TBaseVirtualTree.InternalAddToSelection(const NewItems: TNodeArray; NewLength: Integer;
  ForceInsert: Boolean): Boolean;

var
  I, J: Integer;
  CurrentEnd: Integer;
  Constrained,
  SiblingConstrained: Boolean;

begin
  
  if ForceInsert then
  begin
    for I := 0 to NewLength - 1 do
    begin
      Include(NewItems[I].States, vsSelected);
      if Assigned(FOnAddToSelection) then
        FOnAddToSelection(Self, NewItems[I]);
    end;
  end
  else
  begin
    Constrained := toLevelSelectConstraint in FOptions.FSelectionOptions;
    if Constrained and (FLastSelectionLevel = -1) then
      FLastSelectionLevel := GetNodeLevel(NewItems[0]);
    SiblingConstrained := toSiblingSelectConstraint in FOptions.FSelectionOptions;
    if SiblingConstrained and (FRangeAnchor = nil) then
      FRangeAnchor := NewItems[0];

    for I := 0 to NewLength - 1 do
      if ([vsSelected, vsDisabled] * NewItems[I].States <> []) or
         (Constrained and (Cardinal(FLastSelectionLevel) <> GetNodeLevel(NewItems[I]))) or
         (SiblingConstrained and (FRangeAnchor.Parent <> NewItems[I].Parent)) then
        Inc(PAnsiChar(NewItems[I]))
      else
      begin
        Include(NewItems[I].States, vsSelected);
        if Assigned(FOnAddToSelection) then
          FOnAddToSelection(Self, NewItems[I]);
      end;
  end;

  I := PackArray(NewItems, NewLength);
  if I > -1 then
    NewLength := I;

  Result := NewLength > 0;
  if Result then
  begin
    
    if NewLength > 1 then
      QuickSort(NewItems, 0, NewLength - 1);
    
    if FSelectionCount + NewLength >= Length(FSelection) then
      SetLength(FSelection, FSelectionCount + NewLength);
    
    J := NewLength - 1;
    CurrentEnd := FSelectionCount - 1;

    while J >= 0 do
    begin
      
      if CurrentEnd >= 0 then
      begin
        while (J >= 0) and (PAnsiChar(NewItems[J]) > PAnsiChar(FSelection[CurrentEnd])) do
        begin
          FSelection[CurrentEnd + J + 1] := NewItems[J];
          Dec(J);
        end;
        
        if J < 0 then
          Break;
      end
      else
      begin
        
        Move(NewItems[0], FSelection[0], (J + 1) * SizeOf(Pointer));
        
        Break;
      end;
      
      FindNodeInSelection(NewItems[J], I, 0, CurrentEnd);
      Dec(I);
      
      Move(FSelection[I + 1], FSelection[I + J + 2], (CurrentEnd - I) * SizeOf(Pointer));
      CurrentEnd := I;
    end;

    Inc(FSelectionCount, NewLength);
  end;
end;

procedure TBaseVirtualTree.InternalCacheNode(Node: PVirtualNode);

var
  Len: Cardinal;

begin
  Len := Length(FTempNodeCache);
  if FTempNodeCount = Len then
  begin
    if Len < 100 then
      Len := 100
    else
      Len := Len + Len div 10;
    SetLength(FTempNodeCache, Len);
  end;
  FTempNodeCache[FTempNodeCount] := Node;
  Inc(FTempNodeCount);
end;

procedure TBaseVirtualTree.InternalClearSelection;

var
  Count: Integer;

begin
  
  if FUpdateCount > 0 then
  begin
    Count := PackArray(FSelection, FSelectionCount);
    if Count > -1 then
    begin
      FSelectionCount := Count;
      SetLength(FSelection, FSelectionCount);
    end;
  end;

  while FSelectionCount > 0 do
  begin
    Dec(FSelectionCount);
    Exclude(FSelection[FSelectionCount].States, vsSelected);
    DoRemoveFromSelection(FSelection[FSelectionCount]);
  end;
  ResetRangeAnchor;
  FSelection := nil;
  DoStateChange([], [tsClearPending]);
end;

procedure TBaseVirtualTree.InternalConnectNode(Node, Destination: PVirtualNode; Target: TBaseVirtualTree;
  Mode: TVTNodeAttachMode);

var
  Run: PVirtualNode;

begin
  
  with Target do
  begin
    case Mode of
      amInsertBefore:
        begin
          Node.PrevSibling := Destination.PrevSibling;
          Destination.PrevSibling := Node;
          Node.NextSibling := Destination;
          Node.Parent := Destination.Parent;
          Node.Index := Destination.Index;
          if Node.PrevSibling = nil then
            Node.Parent.FirstChild := Node
          else
            Node.PrevSibling.NextSibling := Node;
          
          Run := Destination;
          while Assigned(Run) do
          begin
            Inc(Run.Index);
            Run := Run.NextSibling;
          end;

          Inc(Destination.Parent.ChildCount);
          Include(Destination.Parent.States, vsHasChildren);
          AdjustTotalCount(Destination.Parent, Node.TotalCount, True);
          
          if FullyVisible[Node] then
          begin
            AdjustTotalHeight(Destination.Parent, Node.TotalHeight, True);
            Inc(FVisibleCount, CountVisibleChildren(Node) + Cardinal(IfThen(IsEffectivelyVisible[Node], 1)));
          end;
        end;
      amInsertAfter:
        begin
          Node.NextSibling := Destination.NextSibling;
          Destination.NextSibling := Node;
          Node.PrevSibling := Destination;
          Node.Parent := Destination.Parent;
          if Node.NextSibling = nil then
            Node.Parent.LastChild := Node
          else
            Node.NextSibling.PrevSibling := Node;
          Node.Index := Destination.Index;
          
          Run := Node;
          while Assigned(Run) do
          begin
            Inc(Run.Index);
            Run := Run.NextSibling;
          end;

          Inc(Destination.Parent.ChildCount);
          Include(Destination.Parent.States, vsHasChildren);
          AdjustTotalCount(Destination.Parent, Node.TotalCount, True);
          
          if FullyVisible[Node] then
          begin
            AdjustTotalHeight(Destination.Parent, Node.TotalHeight, True);
            Inc(FVisibleCount, CountVisibleChildren(Node) + Cardinal(IfThen(IsEffectivelyVisible[Node], 1)));
          end;
        end;
      amAddChildFirst:
        begin
          if Assigned(Destination.FirstChild) then
          begin
            
            Destination.FirstChild.PrevSibling := Node;
            Node.NextSibling := Destination.FirstChild;
            Destination.FirstChild := Node;
          end
          else
          begin
            
            Destination.FirstChild := Node;
            Destination.LastChild := Node;
            Node.NextSibling := nil;
          end;
          Node.PrevSibling := nil;
          Node.Parent := Destination;
          Node.Index := 0;
          
          Run := Node.NextSibling;
          while Assigned(Run) do
          begin
            Inc(Run.Index);
            Run := Run.NextSibling;
          end;

          Inc(Destination.ChildCount);
          Include(Destination.States, vsHasChildren);
          AdjustTotalCount(Destination, Node.TotalCount, True);
          
          if FullyVisible[Node] then
          begin
            AdjustTotalHeight(Destination, Node.TotalHeight, True);
            Inc(FVisibleCount, CountVisibleChildren(Node) + Cardinal(IfThen(IsEffectivelyVisible[Node], 1)));
          end;
        end;
      amAddChildLast:
        begin
          if Assigned(Destination.LastChild) then
          begin
            
            Destination.LastChild.NextSibling := Node;
            Node.PrevSibling := Destination.LastChild;
            Destination.LastChild := Node;
          end
          else
          begin
            
            Destination.FirstChild := Node;
            Destination.LastChild := Node;
            Node.PrevSibling := nil;
          end;
          Node.NextSibling := nil;
          Node.Parent := Destination;
          if Assigned(Node.PrevSibling) then
            Node.Index := Node.PrevSibling.Index + 1
          else
            Node.Index := 0;
          Inc(Destination.ChildCount);
          Include(Destination.States, vsHasChildren);
          AdjustTotalCount(Destination, Node.TotalCount, True);
          
          if FullyVisible[Node] then
          begin
            AdjustTotalHeight(Destination, Node.TotalHeight, True);
            Inc(FVisibleCount, CountVisibleChildren(Node) + Cardinal(IfThen(IsEffectivelyVisible[Node], 1)));
          end;
        end;
    else
      
    end;
    
    Node.States := Node.States - [vsChecking, vsCutOrCopy, vsDeleting, vsClearing];
    
    if (Mode <> amNoWhere) and (Node.Parent <> FRoot) then
    begin
      
      if IsEffectivelyVisible[Node] then
        Exclude(Node.Parent.States, vsAllChildrenHidden)
      else
        
        if Node.Parent.ChildCount = 1 then
          Include(Node.Parent.States, vsAllChildrenHidden);
    end;
  end;
end;

function TBaseVirtualTree.InternalData(Node: PVirtualNode): Pointer;

begin
  Result := nil;
end;

procedure TBaseVirtualTree.InternalDisconnectNode(Node: PVirtualNode; KeepFocus: Boolean; Reindex: Boolean = True);

var
  Parent,
  Run: PVirtualNode;
  Index: Integer;
  AdjustHeight: Boolean;

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Node must neither be nil nor the root node.');

  if (Node = FFocusedNode) and not KeepFocus then
  begin
    DoFocusNode(nil, False);
    DoFocusChange(FFocusedNode, FFocusedColumn);
  end;

  if Node = FRangeAnchor then
    ResetRangeAnchor;
  
  if (Node.Parent <> FRoot) and not (vsClearing in Node.Parent.States) then
    if FUpdateCount = 0 then
      DetermineHiddenChildrenFlag(Node.Parent)
    else
      Include(FStates, tsUpdateHiddenChildrenNeeded);

  if not (vsDeleting in Node.States) then
  begin
    
    Node.States := Node.States - [vsChecking];
    Parent := Node.Parent;
    Dec(Parent.ChildCount);
    AdjustHeight := (vsExpanded in Parent.States) and (vsVisible in Node.States);
    if Parent.ChildCount = 0 then
    begin
      Parent.States := Parent.States - [vsAllChildrenHidden, vsHasChildren];
      if (Parent <> FRoot) and (vsExpanded in Parent.States) then
        Exclude(Parent.States, vsExpanded);
    end;
    AdjustTotalCount(Parent, -Integer(Node.TotalCount), True);
    if AdjustHeight then
      AdjustTotalHeight(Parent, -Integer(Node.TotalHeight), True);
    if FullyVisible[Node] then
      Dec(FVisibleCount, CountVisibleChildren(Node) + Cardinal(IfThen(IsEffectivelyVisible[Node], 1)));

    if Assigned(Node.PrevSibling) then
      Node.PrevSibling.NextSibling := Node.NextSibling
    else
      Parent.FirstChild := Node.NextSibling;

    if Assigned(Node.NextSibling) then
    begin
      Node.NextSibling.PrevSibling := Node.PrevSibling;
      
      if Reindex then
      begin
        Run := Node.NextSibling;
        Index := Node.Index;
        while Assigned(Run) do
        begin
          Run.Index := Index;
          Inc(Index);
          Run := Run.NextSibling;
        end;
      end;
    end
    else
      Parent.LastChild := Node.PrevSibling;
  end;
end;

procedure TBaseVirtualTree.InternalRemoveFromSelection(Node: PVirtualNode);

var
  Index: Integer;

begin
  
  if FindNodeInSelection(Node, Index, -1, -1) then
  begin
    Exclude(Node.States, vsSelected);
    Inc(PAnsiChar(FSelection[Index]));
    DoRemoveFromSelection(Node);
    AdviseChangeEvent(False, Node, crIgnore);
  end;
end;

procedure TBaseVirtualTree.InvalidateCache;

begin
  DoStateChange([tsValidationNeeded], [tsUseCache]);
end;

procedure TBaseVirtualTree.MarkCutCopyNodes;

var
  Nodes: TNodeArray;
  I: Integer;

begin
  Nodes := nil;
  if FSelectionCount > 0 then
  begin
    
    Nodes := GetSortedSelection(False);
    for I := 0 to High(Nodes) do
      with Nodes[I]^ do
        if not (vsDisabled in States) then
          Include(States, vsCutOrCopy);
  end;
end;

procedure TBaseVirtualTree.Loaded;

var
  LastRootCount: Cardinal;
  IsReadOnly: Boolean;

begin
  inherited;
  {$IF CompilerVersion >= 23}
    FSavedBorderWidth := BorderWidth;
    FSavedBevelKind := BevelKind;
  {$IFEND}
  VclStyleChanged;
  
  if (tsNeedRootCountUpdate in FStates) and (FRoot.ChildCount > 0) then
  begin
    DoStateChange([], [tsNeedRootCountUpdate]);
    IsReadOnly := toReadOnly in FOptions.FMiscOptions;
    Exclude(FOptions.FMiscOptions, toReadOnly);
    LastRootCount := FRoot.ChildCount;
    FRoot.ChildCount := 0;
    BeginUpdate;
    SetChildCount(FRoot, LastRootCount);
    EndUpdate;
    if IsReadOnly then
      Include(FOptions.FMiscOptions, toReadOnly);
  end;
  
  Updating;
  try
    FHeader.UpdateMainColumn;
    FHeader.FColumns.FixPositions;
    if toAutoBidiColumnOrdering in FOptions.FAutoOptions then
      FHeader.FColumns.ReorderColumns(UseRightToLeftAlignment);
    
    if hsNeedScaling in FHeader.FStates then
      FHeader.RescaleHeader
    else
      FHeader.RecalculateHeader;
    if hoAutoResize in FHeader.FOptions then
      FHeader.FColumns.AdjustAutoSize(InvalidColumn, True);
  finally
    Updated;
  end;
end;

procedure TBaseVirtualTree.MainColumnChanged;

begin
  DoCancelEdit;

  if Assigned(FAccessibleItem) then
    NotifyWinEvent(EVENT_OBJECT_NAMECHANGE, Handle, OBJID_CLIENT, CHILDID_SELF);
end;

procedure TBaseVirtualTree.MouseMove(Shift: TShiftState; X, Y: Integer);

var
  R: TRect;

begin
  if tsNodeHeightTrackPending in FStates then
  begin
    
    Application.CancelHint;
    
    StopWheelPanning;
    
    StopTimer(ExpandTimer);
    StopTimer(EditTimer);
    StopTimer(HeaderTimer);
    StopTimer(ScrollTimer);
    StopTimer(SearchTimer);
    FSearchBuffer := '';
    FLastSearchNode := nil;

    DoStateChange([tsNodeHeightTracking], [tsScrollPending, tsScrolling, tsEditPending, tsOLEDragPending, tsVCLDragPending,
      tsIncrementalSearching, tsNodeHeightTrackPending]);
  end;

  if tsDrawSelPending in FStates then
  begin
    
    if CalculateSelectionRect(X, Y) then
    begin
      InvalidateRect(Handle, @FNewSelRect, False);
      UpdateWindow(Handle);
      if (Abs(FNewSelRect.Right - FNewSelRect.Left) > Mouse.DragThreshold) or
         (Abs(FNewSelRect.Bottom - FNewSelRect.Top) > Mouse.DragThreshold) then
      begin
        if tsClearPending in FStates then
        begin
          DoStateChange([], [tsClearPending]);
          ClearSelection;
        end;
        DoStateChange([tsDrawSelecting], [tsDrawSelPending]);
        
        FocusedColumn := FHeader.MainColumn;
        
        if HandleDrawSelection(X, Y) then
          InvalidateRect(Handle, nil, False);
      end;
    end;
  end
  else
  begin
    if tsNodeHeightTracking in FStates then
    begin
      
      if DoNodeHeightTracking(FHeightTrackNode, FHeightTrackColumn, FHeader.GetShiftState,
        FHeightTrackPoint, Point(X, Y)) then
      begin
        
        if FHeightTrackPoint.Y >= Y then
          Y := FHeightTrackPoint.Y + 1;
        SetNodeHeight(FHeightTrackNode, Y - FHeightTrackPoint.Y);
        UpdateWindow(Handle);
        Exit;
      end;
    end;
    
    if [tsWheelPanning, tsWheelScrolling] * FStates = [tsWheelPanning, tsWheelScrolling] then
    begin
      if ((Abs(FLastClickPos.X - X) >= Mouse.DragThreshold) or (Abs(FLastClickPos.Y - Y) >= Mouse.DragThreshold)) then
        DoStateChange([], [tsWheelScrolling]);
    end;
    
    if (tsOLEDragPending in FStates) and ((Abs(FLastClickPos.X - X) >= FDragThreshold) or
       (Abs(FLastClickPos.Y - Y) >= FDragThreshold)) then
      DoDragging(FLastClickPos)
    else
    begin
      if CanAutoScroll then
        DoAutoScroll(X, Y);
      if [tsWheelPanning, tsWheelScrolling] * FStates <> [] then
        AdjustPanningCursor(X, Y);
      if not IsMouseSelecting then
      begin
        HandleHotTrack(X, Y);
        inherited MouseMove(Shift, X, Y);
      end
      else
      begin
        
        if not (tsScrolling in FStates) and CalculateSelectionRect(X, Y) then
        begin
          
          if HandleDrawSelection(X, Y) then
            InvalidateRect(Handle, nil, False)
          else
          begin
            UnionRect(R, OrderRect(FNewSelRect), OrderRect(FLastSelRect));
            OffsetRect(R, -FEffectiveOffsetX, FOffsetY);
            InvalidateRect(Handle, @R, False);
          end;
          UpdateWindow(Handle);
        end;
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.Notification(AComponent: TComponent; Operation: TOperation);

begin
  if (AComponent <> Self) and (Operation = opRemove) then
  begin
    
    if AComponent = FImages then
    begin
      Images := nil;
      if not (csDestroying in ComponentState) then
        Invalidate;
    end
    else
      if AComponent = FStateImages then
      begin
        StateImages := nil;
        if not (csDestroying in ComponentState) then
          Invalidate;
      end
      else
        if AComponent = FCustomCheckImages then
        begin
          CustomCheckImages := nil;
          FCheckImageKind := ckSystemDefault;
          if not (csDestroying in ComponentState) then
            Invalidate;
        end
        else
          if AComponent = PopupMenu then
            PopupMenu := nil
          else
            
            if Assigned(FHeader) then
            begin
              if AComponent = FHeader.FImages then
                FHeader.Images := nil
              else
                if AComponent = FHeader.PopupMenu then
                  FHeader.PopupMenu := nil;
            end;
  end;
  inherited;
end;

procedure TBaseVirtualTree.OriginalWMNCPaint(DC: HDC);

const
  InnerStyles: array[TBevelCut] of Integer = (0, BDR_SUNKENINNER, BDR_RAISEDINNER, 0);
  OuterStyles: array[TBevelCut] of Integer = (0, BDR_SUNKENOUTER, BDR_RAISEDOUTER, 0);
  EdgeStyles: array[TBevelKind] of Integer = (0, 0, BF_SOFT, BF_FLAT);
  Ctl3DStyles: array[Boolean] of Integer = (BF_MONO, 0);

var
  RC, RW: TRect;
  EdgeSize: Integer;
  Size: TSize;

begin
  if (BevelKind <> bkNone) or (BorderWidth > 0) then
  begin
    RC := Rect(0, 0, Width, Height);
    Size := GetBorderDimensions;
    InflateRect(RC, Size.cx, Size.cy);

    RW := RC;

    if BevelKind <> bkNone then
    begin
      DrawEdge(DC, RC, InnerStyles[BevelInner] or OuterStyles[BevelOuter], Byte(BevelEdges) or EdgeStyles[BevelKind] or
        Ctl3DStyles[Ctl3D]);

      EdgeSize := 0;
      if BevelInner <> bvNone then
        Inc(EdgeSize, BevelWidth);
      if BevelOuter <> bvNone then
        Inc(EdgeSize, BevelWidth);
      with TWithSafeRect(RC) do
      begin
        if beLeft in BevelEdges then
          Inc(Left, EdgeSize);
        if beTop in BevelEdges then
          Inc(Top, EdgeSize);
        if beRight in BevelEdges then
          Dec(Right, EdgeSize);
        if beBottom in BevelEdges then
          Dec(Bottom, EdgeSize);
      end;
    end;
    
    IntersectClipRect(DC, RC.Left, RC.Top, RC.Right, RC.Bottom);
    
    InflateRect(RC, -Integer(BorderWidth), -Integer(BorderWidth));
    
    ExcludeClipRect(DC, RC.Left, RC.Top, RC.Right, RC.Bottom);
    
    Brush.Color := FColors.BorderColor;
    Windows.FillRect(DC, RW, Brush.Handle);
  end;
end;

procedure TBaseVirtualTree.Paint;

var
  Window: TRect;
  Target: TPoint;
  Temp: Integer;
  Options: TVTInternalPaintOptions;
  RTLOffset: Integer;

begin
  Options := [poBackground, poColumnColor, poDrawFocusRect, poDrawDropMark, poDrawSelection, poGridLines];
  if UseRightToLeftAlignment and FHeader.UseColumns then
    RTLOffset := ComputeRTLOffset(True)
  else
    RTLOffset := 0;
  
  if not IsRectEmpty(FUpdateRect) then
  begin
    Temp := Header.Columns.GetVisibleFixedWidth;
    if Temp = 0 then
    begin
      Window := FUpdateRect;
      Target := Window.TopLeft;
      
      OffsetRect(Window, FEffectiveOffsetX - RTLOffset, -FOffsetY);
      PaintTree(Canvas, Window, Target, Options);
    end
    else
    begin
      
      Window := ClientRect;
      Window.Right := Temp;
      Target := Window.TopLeft;

      OffsetRect(Window,  -RTLOffset, -FOffsetY);
      PaintTree(Canvas, Window, Target, Options);
      
      Window := GetClientRect;

      if Temp > Window.Right then
        Exit;

      Window.Left := Temp;
      Target := Window.TopLeft;

      OffsetRect(Window, FEffectiveOffsetX - RTLOffset, -FOffsetY);
      PaintTree(Canvas, Window, Target, Options);
    end;
  end;
end;

procedure TBaseVirtualTree.PaintCheckImage(Canvas: TCanvas; const ImageInfo: TVTImageInfo; Selected: Boolean);

var
  ForegroundColor: COLORREF;
  R: TRect;
  Details: TThemedElementDetails;

begin
  with ImageInfo do
  begin
    if (tsUseThemes in FStates) and (FCheckImageKind = ckSystemDefault) then
    begin
      R := Rect(XPos - 1, YPos + 1, XPos + 16, YPos + 16);
      Details.Element := teButton;
      case Index of
        
        1 : Details := StyleServices.GetElementDetails(tbRadioButtonUncheckedNormal);
        2 : Details := StyleServices.GetElementDetails(tbRadioButtonUncheckedHot);
        3 : Details := StyleServices.GetElementDetails(tbRadioButtonUncheckedPressed);
        4 : Details := StyleServices.GetElementDetails(tbRadioButtonUncheckedDisabled);
        5 : Details := StyleServices.GetElementDetails(tbRadioButtonCheckedNormal);
        6 : Details := StyleServices.GetElementDetails(tbRadioButtonCheckedHot);
        7 : Details := StyleServices.GetElementDetails(tbRadioButtonCheckedPressed);
        8 : Details := StyleServices.GetElementDetails(tbRadioButtonCheckedDisabled);
       
        9 : Details := StyleServices.GetElementDetails(tbCheckBoxUncheckedNormal);
       10 : Details := StyleServices.GetElementDetails(tbCheckBoxUncheckedHot);
       11 : Details := StyleServices.GetElementDetails(tbCheckBoxUncheckedPressed);
       12 : Details := StyleServices.GetElementDetails(tbCheckBoxUncheckedDisabled);
       13 : Details := StyleServices.GetElementDetails(tbCheckBoxCheckedNormal);
       14 : Details := StyleServices.GetElementDetails(tbCheckBoxCheckedHot);
       15 : Details := StyleServices.GetElementDetails(tbCheckBoxCheckedPressed);
       16 : Details := StyleServices.GetElementDetails(tbCheckBoxCheckedDisabled);
       17 : Details := StyleServices.GetElementDetails(tbCheckBoxMixedNormal);
       18 : Details := StyleServices.GetElementDetails(tbCheckBoxMixedHot);
       19 : Details := StyleServices.GetElementDetails(tbCheckBoxMixedPressed);
       20 : Details := StyleServices.GetElementDetails(tbCheckBoxMixedDisabled);
       
       21 : Details := StyleServices.GetElementDetails(tbPushButtonNormal);
       22 : Details := StyleServices.GetElementDetails(tbPushButtonHot);
       23 : Details := StyleServices.GetElementDetails(tbPushButtonPressed);
       24 : Details := StyleServices.GetElementDetails(tbPushButtonDisabled);
      else
        Details := StyleServices.GetElementDetails(tbButtonRoot);
      end;
      StyleServices.DrawElement(Canvas.Handle, Details, R);
      if Index in [21..24] then
        UtilityImages.Draw(Canvas, XPos - 1, YPos, 4);
    end
    else
      with FCheckImages do
      begin
        if Selected and not Ghosted then
        begin
          if Focused or (toPopupMode in FOptions.FPaintOptions) then
            ForegroundColor := ColorToRGB(FColors.FocusedSelectionColor)
          else
            ForegroundColor := ColorToRGB(FColors.UnfocusedSelectionColor);
        end
        else
          ForegroundColor := GetRGBColor(BlendColor);

          ImageList_DrawEx(Handle, Index, Canvas.Handle, XPos, YPos, 0, 0, GetRGBColor(BkColor), ForegroundColor,
            ILD_TRANSPARENT);
      end;
  end;
end;

type
  TCustomImageListCast = class(TCustomImageList);

procedure DrawImage(ImageList: TCustomImageList; Index: Integer; Canvas: TCanvas; X, Y: Integer; Style: Cardinal; Enabled: Boolean);

  procedure DrawDisabledImage(ImageList: TCustomImageList; Canvas: TCanvas; X, Y, Index: Integer);
  {$if CompilerVersion >= 21}
  var
    Params: TImageListDrawParams;
  begin
    FillChar(Params, SizeOf(Params), 0);
    Params.cbSize := SizeOf(Params);
    Params.himl := ImageList.Handle;
    Params.i := Index;
    Params.hdcDst := Canvas.Handle;
    Params.x := X;
    Params.y := Y;
    Params.fState := ILS_SATURATE;
    ImageList_DrawIndirect(@Params);
  {$else}
  begin
    TCustomImageListCast(ImageList).DoDraw(Index, Canvas, X, Y, Style, False);
  {$ifend}
  end;

begin
  if Enabled then
    TCustomImageListCast(ImageList).DoDraw(Index, Canvas, X, Y, Style, Enabled)
  else
    DrawDisabledImage(ImageList, Canvas, X, Y, Index);
end;

procedure TBaseVirtualTree.PaintImage(var PaintInfo: TVTPaintInfo; ImageInfoIndex: TVTImageInfoIndex; DoOverlay: Boolean);
const
  Style: array[TImageType] of Cardinal = (0, ILD_MASK);
var
  ExtraStyle: Cardinal;
  CutNode: Boolean;
  PaintFocused: Boolean;
  DrawEnabled: Boolean;

begin
  with PaintInfo do
  begin
    CutNode := (vsCutOrCopy in Node.States) and (tsCutPending in FStates);
    PaintFocused := Focused or (toGhostedIfUnfocused in FOptions.FPaintOptions);
    
    if DoOverlay then
      GetImageIndex(PaintInfo, ikOverlay, iiOverlay, Images)
    else
      PaintInfo.ImageInfo[iiOverlay].Index := -1;

    DrawEnabled := not (vsDisabled in Node.States) and Enabled;
    with ImageInfo[ImageInfoIndex] do
    begin
       if (vsSelected in Node.States) and not(Ghosted or CutNode) then
      begin
        if PaintFocused or (toPopupMode in FOptions.FPaintOptions) then
          Images.BlendColor := FColors.FocusedSelectionColor
        else
          Images.BlendColor := FColors.UnfocusedSelectionColor;
      end
      else
        Images.BlendColor := Color;
      
      if (ImageInfo[iiOverlay].Index > -1) and (ImageInfo[iiOverlay].Index < 15) then
        ExtraStyle := ILD_TRANSPARENT or ILD_OVERLAYMASK and IndexToOverlayMask(ImageInfo[iiOverlay].Index + 1)
      else
        ExtraStyle := ILD_TRANSPARENT;
      
      if (toUseBlendedImages in FOptions.FPaintOptions) and PaintFocused
        
        and (Ghosted or
        
        ((vsSelected in Node.States) and
        not (toFullRowSelect in FOptions.FSelectionOptions) and
        not (toGridExtensions in FOptions.FMiscOptions)) or
        
        CutNode) then
        ExtraStyle := ExtraStyle or ILD_BLEND50;

      if (vsSelected in Node.States) and not Ghosted then
        Images.BlendColor := clDefault;

      DrawImage(Images, Index, Canvas, XPos, YPos, Style[Images.ImageType] or ExtraStyle, DrawEnabled);
      
      if PaintInfo.ImageInfo[iiOverlay].Index >= 15 then
        
        DrawImage(ImageInfo[iiOverlay].Images, ImageInfo[iiOverlay].Index, Canvas, XPos, YPos,
          Style[ImageInfo[iiOverlay].Images.ImageType] or ExtraStyle, DrawEnabled);
    end;
  end;
end;

procedure TBaseVirtualTree.PaintNodeButton(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; const R: TRect;
  ButtonX, ButtonY: Integer; BidiMode: TBiDiMode);

var
  Bitmap: TBitmap;
  XPos: Integer;
  IsHot: Boolean;
  Theme: HTHEME;
  Glyph: Integer;
  State: Integer;
  Pos: TRect;

begin
  IsHot := (toHotTrack in FOptions.FPaintOptions) and (FCurrentHotNode = Node) and FHotNodeButtonHit;

  if vsExpanded in Node.States then
  begin
    if IsHot then
      Bitmap := FHotMinusBM
    else
      Bitmap := FMinusBM;
  end
  else
  begin
    if IsHot then
      Bitmap := FHotPlusBM
    else
      Bitmap := FPlusBM;
  end;
  
  if BidiMode = bdLeftToRight then
    XPos := R.Left + ButtonX
  else
    XPos := R.Right - ButtonX - Bitmap.Width;

  if tsUseExplorerTheme in FStates then
  begin
    Glyph := IfThen(IsHot, TVP_HOTGLYPH, TVP_GLYPH);
    State := IfThen(vsExpanded in Node.States, GLPS_OPENED, GLPS_CLOSED);
    Pos := Rect(XPos, R.Top + ButtonY, XPos + Bitmap.Width, R.Top + ButtonY + Bitmap.Height);
    Theme := OpenThemeData(Handle, 'TREEVIEW');
    DrawThemeBackground(Theme, Canvas.Handle, Glyph, State, Pos, nil);
    CloseThemeData(Theme);
  end
  else
    
    Canvas.Draw(XPos, R.Top + ButtonY, Bitmap);
end;

procedure TBaseVirtualTree.PaintTreeLines(const PaintInfo: TVTPaintInfo; VAlignment, IndentSize: Integer;
  LineImage: TLineImage);

var
  I: Integer;
  XPos,
  Offset: Integer;
  NewStyles: TLineImage;

begin
  NewStyles := nil;

  with PaintInfo do
  begin
    if BidiMode = bdLeftToRight then
    begin
      XPos := CellRect.Left;
      Offset := FIndent;
    end
    else
    begin
      Offset := -Integer(FIndent);
      XPos := CellRect.Right + Offset;
    end;

    case FLineMode of
      lmBands:
        if poGridLines in PaintInfo.PaintOptions then
        begin
          
          SetLength(NewStyles, Length(LineImage));
          for I := IndentSize - 1 downto 0 do
          begin
            if (vsExpanded in Node.States) and not (vsAllChildrenHidden in Node.States) then
              NewStyles[I] := ltLeft
            else
              case LineImage[I] of
                ltRight,
                ltBottomRight,
                ltTopDownRight,
                ltTopRight:
                  NewStyles[I] := ltLeftBottom;
                ltNone:
                  
                  if LineImage[I + 1] in [ltNone, ltTopRight] then
                    NewStyles[I] := NewStyles[I + 1]
                  else
                    NewStyles[I] := ltLeft;
                ltTopDown:
                  
                  if LineImage[I + 1] in [ltNone, ltTopRight] then
                    NewStyles[I] := NewStyles[I + 1]
                  else
                    NewStyles[I] := ltLeft;
              end;
          end;

          PaintInfo.Canvas.Font.Color := FColors.GridLineColor;
          for I := 0 to IndentSize - 1 do
          begin
            DoBeforeDrawLineImage(PaintInfo.Node, I + Ord(not (toShowRoot in TreeOptions.PaintOptions)), XPos);
            DrawLineImage(PaintInfo, XPos, CellRect.Top, NodeHeight[Node] - 1, VAlignment - 1, NewStyles[I],
              BidiMode <> bdLeftToRight);
            Inc(XPos, Offset);
          end;
        end;
    else 
      PaintInfo.Canvas.Font.Color := FColors.TreeLineColor;
      for I := 0 to IndentSize - 1 do
      begin
        DoBeforeDrawLineImage(PaintInfo.Node, I + Ord(not (toShowRoot in TreeOptions.PaintOptions)), XPos);
        DrawLineImage(PaintInfo, XPos, CellRect.Top, NodeHeight[Node], VAlignment - 1, LineImage[I],
          BidiMode <> bdLeftToRight);
        Inc(XPos, Offset);
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.PaintSelectionRectangle(Target: TCanvas; WindowOrgX: Integer; const SelectionRect: TRect;
  TargetRect: TRect);

var
  BlendRect: TRect;
  TextColorBackup,
  BackColorBackup: COLORREF;   

begin
  if ((FDrawSelectionMode = smDottedRectangle) and not (tsUseThemes in FStates)) or
    not MMXAvailable then
  begin
    
    TextColorBackup := GetTextColor(Target.Handle);
    SetTextColor(Target.Handle, $FFFFFF);
    BackColorBackup := GetBkColor(Target.Handle);
    SetBkColor(Target.Handle, 0);
    Target.DrawFocusRect(SelectionRect);
    SetTextColor(Target.Handle, TextColorBackup);
    SetBkColor(Target.Handle, BackColorBackup);
  end
  else
  begin
    
    OffsetRect(TargetRect, WindowOrgX, 0);
    if IntersectRect(BlendRect, OrderRect(SelectionRect), TargetRect) then
    begin
      OffsetRect(BlendRect, -WindowOrgX, 0);
      AlphaBlend(0, Target.Handle, BlendRect, Point(0, 0), bmConstantAlphaAndColor, FSelectionBlendFactor,
        ColorToRGB(FColors.SelectionRectangleBlendColor));

      Target.Brush.Color := FColors.SelectionRectangleBorderColor;
      Target.FrameRect(SelectionRect);
    end;
  end;
end;

procedure TBaseVirtualTree.PanningWindowProc(var Message: TMessage);

var
  PS: TPaintStruct;
  Canvas: TCanvas;

begin
  if Message.Msg = WM_PAINT then
  begin
    BeginPaint(FPanningWindow, PS);
    Canvas := TCanvas.Create;
    Canvas.Handle := PS.hdc;
    try
      Canvas.Draw(0, 0, FPanningImage);
    finally
      Canvas.Handle := 0;
      Canvas.Free;
      EndPaint(FPanningWindow, PS);
    end;
    Message.Result := 0;
  end
  else
    with Message do
      Result := DefWindowProc(FPanningWindow, Msg, wParam, lParam);
end;

procedure TBaseVirtualTree.PrepareCell(var PaintInfo: TVTPaintInfo; WindowOrgX, MaxWidth: Integer);

var
  TextColorBackup,
  BackColorBackup: COLORREF;
  FocusRect,
  InnerRect: TRect;
  RowRect: TRect;
  Theme: HTHEME;
{$if CompilerVersion < 19}
const
  TREIS_HOTSELECTED = 6;
{$ifend}

  procedure AlphaBlendSelection(Color: TColor);

  var
    R: TRect;

  begin
    
    R := InnerRect;
    OffsetRect(R, -WindowOrgX, 0);
    if R.Left < 0 then
      R.Left := 0;
    if R.Right > MaxWidth then
      R.Right := MaxWidth;
    AlphaBlend(0, PaintInfo.Canvas.Handle, R, Point(0, 0), bmConstantAlphaAndColor,
      FSelectionBlendFactor, ColorToRGB(Color));
  end;

  procedure DrawBackground(State: Integer);
  begin
    
    if not (toFullRowSelect in FOptions.FSelectionOptions) or (toGridExtensions in FOptions.FMiscOptions) then
      DrawThemeBackground(Theme, PaintInfo.Canvas.Handle, TVP_TREEITEM, State, InnerRect, nil)
    else
      DrawThemeBackground(Theme, PaintInfo.Canvas.Handle, TVP_TREEITEM, State, RowRect, nil);
  end;

  procedure DrawThemedFocusRect(State: Integer);
  var
    Theme: HTHEME;
  begin
    Theme := OpenThemeData(Application.{$if CompilerVersion >= 20}ActiveFormHandle{$else}Handle{$ifend}, 'Explorer::ItemsView');
    if not (toFullRowSelect in FOptions.FSelectionOptions) or (toGridExtensions in FOptions.FMiscOptions) then
      DrawThemeBackground(Theme, PaintInfo.Canvas.Handle, LVP_LISTDETAIL, State, InnerRect, nil)
    else
      DrawThemeBackground(Theme, PaintInfo.Canvas.Handle, LVP_LISTDETAIL, State, RowRect, nil);
    CloseThemeData(Theme);
  end;

begin
  if tsUseExplorerTheme in FStates then
  begin
    Theme := OpenThemeData(Application.{$if CompilerVersion >= 20}ActiveFormHandle{$else}Handle{$ifend}, 'Explorer::TreeView');
    RowRect := Rect(0, PaintInfo.CellRect.Top, FRangeX, PaintInfo.CellRect.Bottom);
    if (Header.Columns.Count = 0) and (toFullRowSelect in TreeOptions.SelectionOptions) then
      RowRect.Right := ClientWidth;
    if toShowVertGridLines in FOptions.PaintOptions then
      Dec(RowRect.Right);
  end;

  with PaintInfo, Canvas do
  begin
    
    with FHeader.FColumns do
    if poColumnColor in PaintOptions then
    begin
      if (VclStyleEnabled and not (coParentColor in FHeader.FColumns[Column].FOptions)) then
        Brush.Color := FColors.BackGroundColor
      else
        Brush.Color := Items[Column].Color;
      FillRect(CellRect);
     end;
    
    DoBeforeCellPaint(Canvas, Node, Column, cpmPaint, CellRect, ContentRect);

    InnerRect := ContentRect;
    
    if not (toGridExtensions in FOptions.FMiscOptions) then
    begin
      case Alignment of
        taLeftJustify:
          with TWithSafeRect(InnerRect) do
            if Left + NodeWidth < Right then
              Right := Left + NodeWidth;
        taCenter:
          with TWithSafeRect(InnerRect) do
            if (Right - Left) > NodeWidth then
            begin
              Left := (Left + Right - NodeWidth) div 2;
              Right := Left + NodeWidth;
            end;
        taRightJustify:
          with TWithSafeRect(InnerRect) do
            if (Right - Left) > NodeWidth then
              Left := Right - NodeWidth;
      end;
    end;

    if (Column = FFocusedColumn) or (toFullRowSelect in FOptions.FSelectionOptions) then
    begin
      
      if poDrawSelection in PaintOptions then
      begin
        if Node = FDropTargetNode then
        begin
          if (FLastDropMode = dmOnNode) or (vsSelected in Node.States) then
          begin
            Brush.Color := FColors.DropTargetColor;
            Pen.Color := FColors.DropTargetBorderColor;

            if (toGridExtensions in FOptions.FMiscOptions) or
              (toFullRowSelect in FOptions.FSelectionOptions) then
              InnerRect := CellRect;
            if not IsRectEmpty(InnerRect) then
              if tsUseExplorerTheme in FStates then
                DrawBackground(TREIS_SELECTED)
              else
                if MMXAvailable and (toUseBlendedSelection in FOptions.PaintOptions) then
                  AlphaBlendSelection(Brush.Color)
                else
                  with TWithSafeRect(InnerRect) do
                    RoundRect(Left, Top, Right, Bottom, FSelectionCurveRadius, FSelectionCurveRadius);
          end
          else
          begin
            Brush.Style := bsClear;
          end;
        end
        else
          if vsSelected in Node.States then
          begin
             if Focused or (toPopupMode in FOptions.FPaintOptions) then
             begin
              Brush.Color := FColors.FocusedSelectionColor;
              Pen.Color := FColors.FocusedSelectionBorderColor;
            end
            else
            begin
              Brush.Color := FColors.UnfocusedSelectionColor;
              Pen.Color := FColors.UnfocusedSelectionBorderColor;
          end;

            if (toGridExtensions in FOptions.FMiscOptions) or (toFullRowSelect in FOptions.FSelectionOptions) then
              InnerRect := CellRect;
            if not IsRectEmpty(InnerRect) then
              if tsUseExplorerTheme in FStates then
              begin
                
                if not (toHotTrack in FOptions.FPaintOptions) or (Node <> FCurrentHotNode) or
                   ((Column <> FCurrentHotColumn) and not (toFullRowSelect in FOptions.FSelectionOptions)) then
                  DrawBackground(IfThen(Self.Focused, TREIS_SELECTED, TREIS_SELECTEDNOTFOCUS));
              end
              else
                if MMXAvailable and (toUseBlendedSelection in FOptions.PaintOptions) then
                  AlphaBlendSelection(Brush.Color)
                else
                  with TWithSafeRect(InnerRect) do
                    RoundRect(Left, Top, Right, Bottom, FSelectionCurveRadius, FSelectionCurveRadius);
          end;
      end;
    end;

    if (tsUseExplorerTheme in FStates) and (toHotTrack in FOptions.FPaintOptions) and (Node = FCurrentHotNode) and
       ((Column = FCurrentHotColumn) or (toFullRowSelect in FOptions.FSelectionOptions)) then
      DrawBackground(IfThen((vsSelected in Node.States) and not (toAlwaysHideSelection in FOptions.FPaintOptions),
                            TREIS_HOTSELECTED, TREIS_HOT));

    if (Column = FFocusedColumn) or (toFullRowSelect in FOptions.FSelectionOptions) then
    begin
      
      if (poDrawFocusRect in PaintOptions) and
         (Focused or (toPopupMode in FOptions.FPaintOptions)) and (FFocusedNode = Node) and
         ( (Column = FFocusedColumn) or
             ((not (toExtendedFocus in FOptions.FSelectionOptions) or IsWinVistaOrAbove) and
             (toFullRowSelect in FOptions.FSelectionOptions) and
             (tsUseExplorerTheme in FStates) ) ) then
      begin
        TextColorBackup := GetTextColor(Handle);
        SetTextColor(Handle, $FFFFFF);
        BackColorBackup := GetBkColor(Handle);
        SetBkColor(Handle, 0);

        if not (toExtendedFocus in FOptions.FSelectionOptions) and (toFullRowSelect in FOptions.FSelectionOptions) and
          (tsUseExplorerTheme in FStates) then
          FocusRect := RowRect
        else
          if toGridExtensions in FOptions.FMiscOptions then
            FocusRect := CellRect
          else
            FocusRect := InnerRect;

        if tsUseExplorerTheme in FStates then
          InflateRect(FocusRect, -1, -1);

        if (tsUseExplorerTheme in FStates) and IsWinVistaOrAbove then begin
          
          if not (vsSelected in Node.States) then
            DrawThemedFocusRect(LIS_NORMAL)
          else
            DrawBackground(TREIS_HOTSELECTED);
        end
        else
          Windows.DrawFocusRect(Handle, FocusRect);
        SetTextColor(Handle, TextColorBackup);
        SetBkColor(Handle, BackColorBackup);
      end;
    end;
  end;

  if tsUseExplorerTheme in FStates then
    CloseThemeData(Theme);
end;

function TBaseVirtualTree.ReadChunk(Stream: TStream; Version: Integer; Node: PVirtualNode; ChunkType,
  ChunkSize: Integer): Boolean;

var
  ChunkBody: TBaseChunkBody;
  Run: PVirtualNode;
  LastPosition: Integer;

begin
  case ChunkType of
    BaseChunk:
      begin
        
        if Version > 1 then
          Stream.Read(ChunkBody, SizeOf(ChunkBody))
        else
        begin
          with ChunkBody do
          begin
            
            Stream.Read(ChildCount, SizeOf(ChildCount));
            Stream.Read(NodeHeight, SizeOf(NodeHeight));
            
            States := [];
            Stream.Read(States, SizeOf(Byte));
            
            if vsVisible in States then
              Include(States, vsSelected)
            else
              Include(States, vsVisible);
            Stream.Read(Align, SizeOf(Align));
            Stream.Read(CheckState, SizeOf(CheckState));
            Stream.Read(CheckType, SizeOf(CheckType));
          end;
        end;

        with Node^ do
        begin
          
          States := ChunkBody.States;
          NodeHeight := ChunkBody.NodeHeight;
          TotalHeight := NodeHeight;
          Align := ChunkBody.Align;
          CheckState := ChunkBody.CheckState;
          CheckType := ChunkBody.CheckType;
          ChildCount := ChunkBody.ChildCount;
          
          while ChunkBody.ChildCount > 0 do
          begin
            Run := MakeNewNode;

            Run.PrevSibling := Node.LastChild;
            if Assigned(Run.PrevSibling) then
              Run.Index := Run.PrevSibling.Index + 1;
            if Assigned(Node.LastChild) then
              Node.LastChild.NextSibling := Run
            else
              Node.FirstChild := Run;
            Node.LastChild := Run;
            Run.Parent := Node;

            ReadNode(Stream, Version, Run);
            Dec(ChunkBody.ChildCount);
          end;
        end;
        Result := True;
      end;
    UserChunk:
      if ChunkSize > 0 then
      begin
        
        LastPosition := Stream.Position;
        DoLoadUserData(Node, Stream);
        
        Result := Stream.Position > LastPosition;
        
        if not Result or (Stream.Position <> (LastPosition + ChunkSize)) then
          Stream.Position := LastPosition + ChunkSize;
      end
      else
        Result := True;
  else
    
    Stream.Position := Stream.Position + ChunkSize;
    Result := False;
  end;
end;

procedure TBaseVirtualTree.ReadNode(Stream: TStream; Version: Integer; Node: PVirtualNode);

var
  Header: TChunkHeader;
  EndPosition: Integer;

begin
  with Stream do
  begin
    
    Stream.Read(Header, SizeOf(Header));
    if Header.ChunkType = NodeChunk then
    begin
      EndPosition := Stream.Position + Header.ChunkSize;
      
      while Position < EndPosition do
      begin
        
        Stream.Read(Header, SizeOf(Header));
        ReadChunk(Stream, Version, Node, Header.ChunkType, Header.ChunkSize);
      end;
      
      if Position <> EndPosition then
        ShowError(SCorruptStream2, hcTFCorruptStream2);
    end
    else
      ShowError(SCorruptStream1, hcTFCorruptStream1);
  end;
end;

procedure TBaseVirtualTree.RedirectFontChangeEvent(Canvas: TCanvas);

begin
  if @Canvas.Font.OnChange <> @FOldFontChange then
  begin
    FOldFontChange := Canvas.Font.OnChange;
    Canvas.Font.OnChange := FontChanged;
  end;
end;

procedure TBaseVirtualTree.RemoveFromSelection(Node: PVirtualNode);

var
  Index: Integer;

begin
  if not FSelectionLocked then
  begin
    Assert(Assigned(Node), 'Node must not be nil!');
    if vsSelected in Node.States then
    begin
      Exclude(Node.States, vsSelected);
      if FindNodeInSelection(Node, Index, -1, -1) and (Index < FSelectionCount - 1) then
        Move(FSelection[Index + 1], FSelection[Index], (FSelectionCount - Index - 1) * SizeOf(Pointer));
      if FSelectionCount > 0 then
        Dec(FSelectionCount);
      SetLength(FSelection, FSelectionCount);

      if FSelectionCount = 0 then
        ResetRangeAnchor;

      DoRemoveFromSelection(Node);
      Change(Node);
    end;
  end;
end;

function TBaseVirtualTree.RenderOLEData(const FormatEtcIn: TFormatEtc; out Medium: TStgMedium;
  ForClipboard: Boolean): HResult;

  procedure WriteNodes(Stream: TStream);

  var
    Selection: TNodeArray;
    I: Integer;

  begin
    if ForClipboard then
      Selection := GetSortedCutCopySet(True)
    else
      Selection := GetSortedSelection(True);
    for I := 0 to High(Selection) do
      WriteNode(Stream, Selection[I]);
  end;

var
  Data: PCardinal;
  ResPointer: Pointer;
  ResSize: Integer;
  OLEStream: IStream;
  VCLStream: TStream;

begin
  ZeroMemory (@Medium, SizeOf(Medium));
  
  if (FormatEtcIn.cfFormat = CF_VIRTUALTREE) and (FormatEtcIn.tymed and (TYMED_HGLOBAL or TYMED_ISTREAM) <> 0) then
  begin
    VCLStream := nil;
    try
      Medium.unkForRelease := nil;
      
      if FormatEtcIn.tymed and TYMED_ISTREAM <> 0 then
      begin
        
        CreateStreamOnHGlobal(0, True, OLEStream);
        VCLStream := TOLEStream.Create(OLEStream);
        WriteNodes(VCLStream);
        
        VCLStream.Position := 0;
        Medium.tymed := TYMED_ISTREAM;
        IUnknown(Medium.stm) := OLEStream;
        Result := S_OK;
      end
      else
      begin
        VCLStream := TMemoryStream.Create;
        WriteNodes(VCLStream);
        ResPointer := TMemoryStream(VCLStream).Memory;
        ResSize := VCLStream.Position;
        
        if ResSize > 0 then
        begin
          Medium.hGlobal := GlobalAlloc(GHND or GMEM_SHARE, ResSize + SizeOf(Cardinal));
          Data := GlobalLock(Medium.hGlobal);
          
          Data^ := ResSize;
          Inc(Data);
          Move(ResPointer^, Data^, ResSize);
          GlobalUnlock(Medium.hGlobal);
          Medium.tymed := TYMED_HGLOBAL;

          Result := S_OK;
        end
        else
          Result := E_FAIL;
      end;
    finally
      
      VCLStream.Free;
    end;
  end
  else 
    Result := DoRenderOLEData(FormatEtcIn, Medium, ForClipboard);
end;

procedure TBaseVirtualTree.ResetRangeAnchor;

begin
  FRangeAnchor := FFocusedNode;
  FLastSelectionLevel := -1;
end;

procedure TBaseVirtualTree.RestoreFontChangeEvent(Canvas: TCanvas);

begin
  Canvas.Font.OnChange := FOldFontChange;
  FOldFontChange := nil;
end;

procedure TBaseVirtualTree.SelectNodes(StartNode, EndNode: PVirtualNode; AddOnly: Boolean);

var
  NodeFrom,
  NodeTo,
  LastAnchor: PVirtualNode;
  Index: Integer;

begin
  Assert(Assigned(EndNode), 'EndNode must not be nil!');
  if not FSelectionLocked then
  begin
    ClearTempCache;
    if StartNode = nil then
      StartNode := GetFirstVisibleNoInit(nil, True)
    else
      if not FullyVisible[StartNode] then
      begin
        StartNode := GetPreviousVisible(StartNode, True);
        if StartNode = nil then
          StartNode := GetFirstVisibleNoInit(nil, True)
      end;

    if CompareNodePositions(StartNode, EndNode, True) < 0 then
    begin
      NodeFrom := StartNode;
      NodeTo := EndNode;
    end
    else
    begin
      NodeFrom := EndNode;
      NodeTo := StartNode;
    end;
    
    LastAnchor := FRangeAnchor;
    if not AddOnly then
      InternalClearSelection;

    while NodeFrom <> NodeTo do
    begin
      InternalCacheNode(NodeFrom);
      NodeFrom := GetNextVisible(NodeFrom, True);
    end;
    
    InternalCacheNode(NodeFrom);
    
    AddToSelection(FTempNodeCache, FTempNodeCount);
    ClearTempCache;
    if Assigned(LastAnchor) and FindNodeInSelection(LastAnchor, Index, -1, -1) then
     FRangeAnchor := LastAnchor;
  end;
end;

procedure TBaseVirtualTree.SetFocusedNodeAndColumn(Node: PVirtualNode; Column: TColumnIndex);

var
  OldColumn: TColumnIndex;
  WasDifferent: Boolean;

begin
  if not FHeader.AllowFocus(Column) then
    Column := FFocusedColumn;

  WasDifferent := (Node <> FFocusedNode) or (Column <> FFocusedColumn);

  OldColumn := FFocusedColumn;
  FFocusedColumn := Column;

  DoFocusNode(Node, True);
  
  if FFocusedNode = Node then
  begin
    CancelEditNode;
    if WasDifferent then
      DoFocusChange(FFocusedNode, FFocusedColumn);
  end
  else
    
    FFocusedColumn := OldColumn;
end;

procedure TBaseVirtualTree.SkipNode(Stream: TStream);

var
  Header: TChunkHeader;

begin
  with Stream do
  begin
    
    Stream.Read(Header, SizeOf(Header));
    if Header.ChunkType = NodeChunk then
      Stream.Position := Stream.Position + Header.ChunkSize
    else
      ShowError(SCorruptStream1, hcTFCorruptStream1);
  end;
end;

var
  PanningWindowClass: TWndClass = (
    style: 0;
    lpfnWndProc: @DefWindowProc;
    cbClsExtra: 0;
    cbWndExtra: 0;
    hInstance: 0;
    hIcon: 0;
    hCursor: 0;
    hbrBackground: 0;
    lpszMenuName: nil;
    lpszClassName: 'VTPanningWindow'
  );

procedure TBaseVirtualTree.StartWheelPanning(Position: TPoint);

  function CreateClipRegion: HRGN;

  var
    Start, X, Y: Integer;
    Temp: HRGN;

  begin
    Assert(not FPanningImage.Empty, 'Invalid wheel panning image.');
    
    Result := CreateRectRgn(0, 0, 0, 0);
    with FPanningImage, Canvas do
    begin
      for Y := 0 to Height - 1 do
      begin
        Start := -1;
        for X := 0 to Width - 1 do
        begin
          
          if (Start = -1) and (Pixels[X, Y] <> clFuchsia) then
            Start := X
          else
            if (Start > -1) and (Pixels[X, Y] = clFuchsia) then
            begin
              
              Temp := CreateRectRgn(Start, Y, X, Y + 1);
              CombineRgn(Result, Result, Temp, RGN_OR);
              DeleteObject(Temp);
              Start := -1;
            end;
        end;
        
        if Start > -1 then
        begin
          Temp := CreateRectRgn(Start, Y, Width, Y + 1);
          CombineRgn(Result, Result, Temp, RGN_OR);
          DeleteObject(Temp);
        end;
      end;
    end;
    
  end;

var
  TempClass: TWndClass;
  ClassRegistered: Boolean;
  ImageName: string;
  Pt: TPoint;

begin
  
  StopTimer(ScrollTimer);
  DoStateChange([tsWheelPanning, tsWheelScrolling]);
  
  PanningWindowClass.hInstance := HInstance;
  ClassRegistered := GetClassInfo(HInstance, PanningWindowClass.lpszClassName, TempClass);
  if not ClassRegistered or (TempClass.lpfnWndProc <> @DefWindowProc) then
  begin
    if ClassRegistered then
      Windows.UnregisterClass(PanningWindowClass.lpszClassName, HInstance);
    Windows.RegisterClass(PanningWindowClass);
  end;
  
  Pt := ClientToScreen(Position);
  FPanningWindow := CreateWindowEx(WS_EX_TOOLWINDOW, PanningWindowClass.lpszClassName, nil, WS_POPUP, Pt.X - 16, Pt.Y - 16,
    32, 32, Handle, 0, HInstance, nil);

  FPanningImage := TBitmap.Create;
  if Integer(FRangeX) > ClientWidth then
  begin
    if Integer(FRangeY) > ClientHeight then
      ImageName := 'VT_MOVEALL'
    else
      ImageName := 'VT_MOVEEW'
  end
  else
    ImageName := 'VT_MOVENS';
  FPanningImage.LoadFromResourceName(HInstance, ImageName);
  SetWindowRgn(FPanningWindow, CreateClipRegion, False);

  {$ifdef CPUX64}
  SetWindowLongPtr(FPanningWindow, GWLP_WNDPROC, LONG_PTR(Classes.MakeObjectInstance(PanningWindowProc)));
  {$else}
  SetWindowLong(FPanningWindow, GWL_WNDPROC, Longint(Classes.MakeObjectInstance(PanningWindowProc)));
  {$endif CPUX64}
  ShowWindow(FPanningWindow, SW_SHOWNOACTIVATE);
  
  SetFocus;
  SetCapture(Handle);
  SetTimer(Handle, ScrollTimer, 20, nil);
end;

procedure TBaseVirtualTree.StopWheelPanning;

var
  Instance: Pointer;

begin
  if [tsWheelPanning, tsWheelScrolling] * FStates <> [] then
  begin
    
    StopTimer(ScrollTimer);
    ReleaseCapture;
    DoStateChange([], [tsWheelPanning, tsWheelScrolling]);
    
    {$ifdef CPUX64}
    Instance := Pointer(GetWindowLongPtr(FPanningWindow, GWLP_WNDPROC));
    {$else}
    Instance := Pointer(GetWindowLong(FPanningWindow, GWL_WNDPROC));
    {$endif CPUX64}
    DestroyWindow(FPanningWindow);
    if Instance <> @DefWindowProc then
      Classes.FreeObjectInstance(Instance);
    FPanningWindow := 0;
    FPanningImage.Free;
    FPanningImage := nil;
    DeleteObject(FPanningCursor);
    FPanningCursor := 0;
    Windows.SetCursor(Screen.Cursors[Cursor]);
  end;
end;

procedure TBaseVirtualTree.StructureChange(Node: PVirtualNode; Reason: TChangeReason);

begin
  AdviseChangeEvent(True, Node, Reason);

  if FUpdateCount = 0 then
  begin
    if (FChangeDelay > 0) and not (tsSynchMode in FStates) then
      SetTimer(Handle, StructureChangeTimer, FChangeDelay, nil)
    else
      DoStructureChange(Node, Reason);
  end;
end;

function TBaseVirtualTree.SuggestDropEffect(Source: TObject; Shift: TShiftState; Pt: TPoint;
  AllowedEffects: Integer): Integer;

begin
  Result := AllowedEffects;
  
  if Assigned(Source) and (Source = Self) then
    if (AllowedEffects and DROPEFFECT_MOVE) <> 0 then
      Result := DROPEFFECT_MOVE
    else 
  else
    
    if (AllowedEffects and DROPEFFECT_COPY) <> 0 then
      Result := DROPEFFECT_COPY;
  
  if ssCtrl in Shift then
  begin
    
    if ssShift in Shift then
    begin
      
      if (AllowedEffects and DROPEFFECT_LINK) <> 0 then
        Result := DROPEFFECT_LINK;
    end
    else
    begin
      
      if (AllowedEffects and DROPEFFECT_COPY) <> 0 then
        Result := DROPEFFECT_COPY;
    end;
  end
  else
  begin
    
    if ssShift in Shift then
    begin
      
      if (AllowedEffects and DROPEFFECT_MOVE) <> 0 then
        Result := DROPEFFECT_MOVE;
    end
    else
    begin
      
      if ssAlt in Shift then
      begin
        
        if (AllowedEffects and DROPEFFECT_LINK) <> 0 then
          Result := DROPEFFECT_LINK;
      end;
      
    end;
  end;
end;

procedure TBaseVirtualTree.ToggleSelection(StartNode, EndNode: PVirtualNode);

var
  NodeFrom,
  NodeTo: PVirtualNode;
  NewSize: Integer;
  Position: Integer;

begin
  if not FSelectionLocked then
  begin
    Assert(Assigned(EndNode), 'EndNode must not be nil!');
    if StartNode = nil then
      StartNode := FRoot.FirstChild
    else
      if not FullyVisible[StartNode] then
        StartNode := GetPreviousVisible(StartNode, True);

    Position := CompareNodePositions(StartNode, EndNode);
    
    if Position <> 0 then
    begin
      if Position < 0 then
      begin
        NodeFrom := StartNode;
        NodeTo := EndNode;
      end
      else
      begin
        NodeFrom := EndNode;
        NodeTo := StartNode;
      end;

      ClearTempCache;
      
      if CompareNodePositions(NodeFrom, FRangeAnchor) < 0 then
        if not (vsSelected in NodeFrom.States) then
          InternalCacheNode(NodeFrom)
        else
          InternalRemoveFromSelection(NodeFrom);
      
      NodeFrom := GetNextVisible(NodeFrom, True);
      while NodeFrom <> NodeTo do
      begin
        if not (vsSelected in NodeFrom.States) then
          InternalCacheNode(NodeFrom)
        else
          InternalRemoveFromSelection(NodeFrom);
        NodeFrom := GetNextVisible(NodeFrom, True);
      end;
      
      if CompareNodePositions(NodeFrom, FRangeAnchor) > 0 then
        if not (vsSelected in NodeFrom.States) then
          InternalCacheNode(NodeFrom)
        else
          InternalRemoveFromSelection(NodeFrom);
      
      NewSize := PackArray(FSelection, FSelectionCount);
      if NewSize > -1 then
      begin
        FSelectionCount := NewSize;
        SetLength(FSelection, FSelectionCount);
      end;
      
      if not (vsSelected in FRangeAnchor.States) then
        InternalCacheNode(FRangeAnchor);
      if FTempNodeCount > 0 then
        AddToSelection(FTempNodeCache, FTempNodeCount);
      ClearTempCache;
    end;
  end;
end;

procedure TBaseVirtualTree.UnselectNodes(StartNode, EndNode: PVirtualNode);

var
  NodeFrom,
  NodeTo: PVirtualNode;
  NewSize: Integer;

begin
  if not FSelectionLocked then
  begin
    Assert(Assigned(EndNode), 'EndNode must not be nil!');

    if StartNode = nil then
      StartNode := FRoot.FirstChild
    else
      if not FullyVisible[StartNode] then
      begin
        StartNode := GetPreviousVisible(StartNode, True);
        if StartNode = nil then
          StartNode := FRoot.FirstChild
      end;

    if CompareNodePositions(StartNode, EndNode) < 0 then
    begin
      NodeFrom := StartNode;
      NodeTo := EndNode;
    end
    else
    begin
      NodeFrom := EndNode;
      NodeTo := StartNode;
    end;

    while NodeFrom <> NodeTo do
    begin
      InternalRemoveFromSelection(NodeFrom);
      NodeFrom := GetNextVisible(NodeFrom, True);
    end;
    
    InternalRemoveFromSelection(NodeFrom);
    
    NewSize := PackArray(FSelection, FSelectionCount);
    if NewSize > -1 then
    begin
      FSelectionCount := NewSize;
      SetLength(FSelection, FSelectionCount);
    end;
  end;
end;

procedure TBaseVirtualTree.UpdateColumnCheckState(Col: TVirtualTreeColumn);

begin
  Col.CheckState := DetermineNextCheckState(Col.CheckType, Col.CheckState);
end;

procedure TBaseVirtualTree.UpdateDesigner;

var
  ParentForm: TCustomForm;

begin
  if (csDesigning in ComponentState) and not (csUpdating in ComponentState) then
  begin
    ParentForm := GetParentForm(Self);
    if Assigned(ParentForm) and Assigned(ParentForm.Designer) then
      ParentForm.Designer.Modified;
  end;
end;

procedure TBaseVirtualTree.UpdateHeaderRect;

var
  OffsetX,
  OffsetY: Integer;
  EdgeSize: Integer;
  Size: TSize;

begin
  FHeaderRect := Rect(0, 0, Width, Height);
  
  Size := GetBorderDimensions;
  InflateRect(FHeaderRect, Size.cx, Size.cy);
  
  OffsetX := BorderWidth;
  OffsetY := BorderWidth;
  if BevelKind <> bkNone then
  begin
    EdgeSize := 0;
    if BevelInner <> bvNone then
      Inc(EdgeSize, BevelWidth);
    if BevelOuter <> bvNone then
      Inc(EdgeSize, BevelWidth);
    if beLeft in BevelEdges then
      Inc(OffsetX, EdgeSize);
    if beTop in BevelEdges then
      Inc(OffsetY, EdgeSize);
  end;

  InflateRect(FHeaderRect, -OffsetX, -OffsetY);

  if hoVisible in FHeader.FOptions then
  begin
    if FHeaderRect.Left <= FHeaderRect.Right then
      FHeaderRect.Bottom := FHeaderRect.Top + Integer(FHeader.FHeight)
    else
      FHeaderRect := Rect(0, 0, 0, 0);
  end
  else
    FHeaderRect.Bottom := FHeaderRect.Top;
end;

procedure TBaseVirtualTree.UpdateEditBounds;

var
  R: TRect;
  Dummy: Integer;
  CurrentAlignment: TAlignment;
  CurrentBidiMode: TBidiMode;

begin
  if (tsEditing in FStates) and Assigned(FFocusedNode) then
  begin
    if (GetCurrentThreadId <> MainThreadID) then begin
      
      Exit;
    end;
    if vsMultiline in FFocusedNode.States then
      R := GetDisplayRect(FFocusedNode, FEditColumn, True, False)
    else
      R := GetDisplayRect(FFocusedNode, FEditColumn, True, True);
    if (toGridExtensions in FOptions.FMiscOptions) then
    begin
      
      if FEditColumn <= NoColumn then
      begin
        CurrentAlignment := Alignment;
        CurrentBidiMode := BiDiMode;
      end
      else
      begin
        CurrentAlignment := FHeader.Columns[FEditColumn].FAlignment;
        CurrentBidiMode := FHeader.Columns[FEditColumn].FBidiMode;
      end;
      
      if CurrentBidiMode <> bdLeftToRight then
        ChangeBiDiModeAlignment(CurrentAlignment);
      if CurrentAlignment = taLeftJustify then
        FHeader.Columns.GetColumnBounds(FEditColumn, Dummy, R.Right)
      else
        FHeader.Columns.GetColumnBounds(FEditColumn, R.Left, Dummy);
    end;
    if toShowHorzGridLines in TreeOptions.PaintOptions then
      Dec(R.Bottom);
    R.Bottom := R.Top + Max(R.Bottom - R.Top, FEditLink.GetBounds.Bottom - FEditLink.GetBounds.Top); 
    FEditLink.SetBounds(R);
  end;
end;

const
  ScrollMasks: array[Boolean] of Cardinal = (0, SIF_DISABLENOSCROLL);

const 
  CLIPRGN = 1;
  METARGN = 2;
  APIRGN = 3;
  SYSRGN = 4;

function GetRandomRgn(DC: HDC; Rgn: HRGN; iNum: Integer): Integer; stdcall; external 'GDI32.DLL';

procedure TBaseVirtualTree.UpdateWindowAndDragImage(const Tree: TBaseVirtualTree; TreeRect: TRect; UpdateNCArea,
  ReshowDragImage: Boolean);

var
  DragRegion,          
  UpdateRegion,        
  NCRegion: HRGN;      
  DragRect,
  NCRect: TRect;
  RedrawFlags: Cardinal;

  VisibleTreeRegion: HRGN;

  DC: HDC;

begin
  if IntersectRect(TreeRect, TreeRect, ClientRect) then
  begin
    
    VisibleTreeRegion := CreateRectRgn(0, 0, 1, 1);
    DC := GetDCEx(Handle, 0, DCX_CACHE or DCX_WINDOW or DCX_CLIPSIBLINGS or DCX_CLIPCHILDREN);
    GetRandomRgn(DC, VisibleTreeRegion, SYSRGN);
    ReleaseDC(Handle, DC);
    
    Tree.FDragImage.RecaptureBackground(Self, TreeRect, VisibleTreeRegion, UpdateNCArea, ReshowDragImage);
    
    DragRect := Tree.FDragImage.GetDragImageRect;
    MapWindowPoints(0, Handle, DragRect, 2);
    DragRegion := CreateRectRgnIndirect(DragRect);
    
    if UpdateNCArea then
    begin
      
      GetWindowRect(Handle, NCRect);
      
      MapWindowPoints(0, Handle, NCRect, 2);
      NCRegion := CreateRectRgnIndirect(NCRect);
      
      UpdateRegion := CreateRectRgnIndirect(ClientRect);
      
      CombineRgn(NCRegion, NCRegion, UpdateRegion, RGN_DIFF);
      
      CombineRgn(NCRegion, NCRegion, DragRegion, RGN_DIFF);
      RedrawWindow(Handle, nil, NCRegion, RDW_FRAME or RDW_NOERASE or RDW_NOCHILDREN or RDW_INVALIDATE or RDW_VALIDATE or
        RDW_UPDATENOW);
      DeleteObject(NCRegion);
      DeleteObject(UpdateRegion);
    end;

    UpdateRegion := CreateRectRgnIndirect(TreeRect);
    RedrawFlags := RDW_INVALIDATE or RDW_VALIDATE or RDW_UPDATENOW or RDW_NOERASE or RDW_NOCHILDREN;
    
    CombineRgn(UpdateRegion, UpdateRegion, DragRegion, RGN_DIFF);
    RedrawWindow(Handle, nil, UpdateRegion, RedrawFlags);
    DeleteObject(UpdateRegion);
    DeleteObject(DragRegion);
    DeleteObject(VisibleTreeRegion);
  end;
end;

procedure TBaseVirtualTree.ValidateCache;

begin
  
  InterruptValidation;

  FStartIndex := 0;
  if (tsValidationNeeded in FStates) and (FVisibleCount > CacheThreshold) then
  begin
    
    WorkerThread.AddTree(Self);
    SetEvent(WorkEvent);
  end;
end;

procedure TBaseVirtualTree.ValidateNodeDataSize(var Size: Integer);

begin
  Size := sizeof(Pointer);
  if Assigned(FOnGetNodeDataSize) then
    FOnGetNodeDataSize(Self, Size);
end;

procedure TBaseVirtualTree.VclStyleChanged;
begin
  {$if CompilerVersion >= 23 }
  FSetOrRestoreBevelKindAndBevelWidth := True;
  FVclStyleEnabled := StyleServices.Enabled and not StyleServices.IsSystemStyle;
  if not VclStyleEnabled then
  begin
    if FSavedBevelKind <> BevelKind then
      BevelKind := FSavedBevelKind;
    if FSavedBorderWidth <> BorderWidth then
      BorderWidth := FSavedBorderWidth;
  end
  else
  begin
    if BevelKind <> bkNone then
      BevelKind := bkNone;
    if BorderWidth <> 0 then
      BorderWidth := 0;
  end;
  FSetOrRestoreBevelKindAndBevelWidth := False;
  {$else}
  FVclStyleEnabled := False;
  {$ifend}
end;

procedure TBaseVirtualTree.WndProc(var Message: TMessage);

var
  Handled: Boolean;

begin
  Handled := False;
  
  if Assigned(FHeader) and (FHeader.FStates <> []) then
    Handled := FHeader.HandleMessage(Message);
  if not Handled then
  begin
    
    if not (csDesigning in ComponentState) and
       ((Message.Msg = WM_LBUTTONDOWN) or (Message.Msg = WM_LBUTTONDBLCLK)) then
    begin
      if (DragMode = dmAutomatic) and (DragKind = dkDrag) then
      begin
        if IsControlMouseMsg(TWMMouse(Message)) then
          Handled := True;
        if not Handled then
        begin
          ControlState := ControlState + [csLButtonDown];
          Dispatch(Message);  
          Handled := True;
        end;
      end;
    end;

    if not Handled and Assigned(FHeader) then
      Handled := FHeader.HandleMessage(Message);

    if not Handled then
    begin
      if (Message.Msg in [WM_NCLBUTTONDOWN, WM_NCRBUTTONDOWN, WM_NCMBUTTONDOWN]) and not Focused and CanFocus then
        SetFocus;
      inherited;
    end;
  end;
end;

procedure TBaseVirtualTree.WriteChunks(Stream: TStream; Node: PVirtualNode);

var
  Header: TChunkHeader;
  LastPosition,
  ChunkSize: Integer;
  Chunk: TBaseChunk;
  Run: PVirtualNode;

begin
  with Stream do
  begin
    
    LastPosition := Position;
    Chunk.Header.ChunkType := BaseChunk;
    with Node^, Chunk do
    begin
      Body.ChildCount := ChildCount;
      Body.NodeHeight := NodeHeight;
      
      Body.States := States - [vsChecking, vsCutOrCopy, vsDeleting, vsOnFreeNodeCallRequired, vsHeightMeasured];
      Body.Align := Align;
      Body.CheckState := CheckState;
      Body.CheckType := CheckType;
      Body.Reserved := 0;
    end;
    
    Write(Chunk, SizeOf(Chunk));
    
    if vsInitialized in Node.States then
    begin
      Run := Node.FirstChild;
      while Assigned(Run) do
      begin
        WriteNode(Stream, Run);
        Run := Run.NextSibling;
      end;
    end;

    FinishChunkHeader(Stream, LastPosition, Position);
    
    LastPosition := Position;
    Header.ChunkType := UserChunk;
    Write(Header, SizeOf(Header));
    DoSaveUserData(Node, Stream);
    
    ChunkSize := Position - LastPosition - SizeOf(TChunkHeader);
    
    if ChunkSize = 0 then
    begin
      Position := LastPosition;
      Size := Size - SizeOf(Header);
    end
    else
      FinishChunkHeader(Stream, LastPosition, Position);
  end;
end;

procedure TBaseVirtualTree.WriteNode(Stream: TStream; Node: PVirtualNode);

var
  LastPosition: Integer;
  Header: TChunkHeader;

begin
  
  if toInitOnSave in FOptions.FMiscOptions then
  begin
    if not (vsInitialized in Node.States) then
      InitNode(Node);
    if (vsHasChildren in Node.States) and (Node.ChildCount = 0) then
      InitChildren(Node);
  end;

  with Stream do
  begin
    LastPosition := Position;
    
    Header.ChunkType := NodeChunk;
    Write(Header, SizeOf(Header));
    
    WriteChunks(Stream, Node);
    
    FinishChunkHeader(Stream, LastPosition, Position);
  end;
end;

function TBaseVirtualTree.AbsoluteIndex(Node: PVirtualNode): Cardinal;

begin
  Result := 0;
  while Assigned(Node) and (Node <> FRoot) do
  begin
    if not (vsInitialized in Node.States) then
      InitNode(Node);
    if Assigned(Node.PrevSibling) then
    begin
      
      Node := Node.PrevSibling;
      Inc(Result, Node.TotalCount);
    end
    else
    begin
      Node := Node.Parent;
      if Node <> FRoot then
        Inc(Result);
    end;
  end;
end;

function TBaseVirtualTree.AddChild(Parent: PVirtualNode; UserData: Pointer = nil): PVirtualNode;

var
  NodeData: ^Pointer;

begin
  if not (toReadOnly in FOptions.FMiscOptions) then
  begin
    CancelEditNode;

    if Parent = nil then
      Parent := FRoot;
    if not (vsInitialized in Parent.States) then
      InitNode(Parent);
    
    Inc(FUpdateCount);
    try
      SetChildCount(Parent, Parent.ChildCount + 1);
      
      Exclude(Parent.States, vsAllChildrenHidden);
    finally
      Dec(FUpdateCount);
    end;
    Result := Parent.LastChild;
    
    if Assigned(UserData) then
      if FNodeDataSize >= SizeOf(Pointer) then
      begin
        NodeData := Pointer(PByte(@Result.Data) + FTotalInternalDataSize);
        NodeData^ := UserData;
        Include(Result.States, vsOnFreeNodeCallRequired);
      end
      else
        ShowError(SCannotSetUserData, hcTFCannotSetUserData);

    InvalidateCache;
    if FUpdateCount = 0 then
    begin
      ValidateCache;
      if tsStructureChangePending in FStates then
      begin
        if Parent = FRoot then
          StructureChange(nil, crChildAdded)
        else
          StructureChange(Parent, crChildAdded);
      end;

      if (toAutoSort in FOptions.FAutoOptions) and (FHeader.FSortColumn > InvalidColumn) then
        Sort(Parent, FHeader.FSortColumn, FHeader.FSortDirection, True);

      InvalidateToBottom(Parent);
      UpdateScrollbars(True);
    end;
  end
  else
    Result := nil;
end;

procedure TBaseVirtualTree.AddFromStream(Stream: TStream; TargetNode: PVirtualNode);

var
  ThisID: TMagicID;
  Version,
  Count: Cardinal;
  Node: PVirtualNode;

begin
  if not (toReadOnly in FOptions.FMiscOptions) then
  begin
    
    Stream.ReadBuffer(ThisID, SizeOf(TMagicID));
    if (ThisID[0] = MagicID[0]) and
       (ThisID[1] = MagicID[1]) and
       (ThisID[2] = MagicID[2]) and
       (ThisID[5] = MagicID[5]) then
    begin
      Version := Word(ThisID[3]);
      if Version <= VTTreeStreamVersion  then
      begin
        BeginUpdate;
        try
          if Version < 2 then
            Count := MaxInt
          else
            Stream.ReadBuffer(Count, SizeOf(Count));

          while (Stream.Position < Stream.Size) and (Count > 0) do
          begin
            Dec(Count);
            Node := MakeNewNode;
            InternalConnectNode(Node, TargetNode, Self, amAddChildLast);
            InternalAddFromStream(Stream, Version, Node);
          end;
          if TargetNode = FRoot then
            DoNodeCopied(nil)
          else
            DoNodeCopied(TargetNode);
        finally
          EndUpdate;
        end;
      end
      else
        ShowError(SWrongStreamVersion, hcTFWrongStreamVersion);
    end
    else
      ShowError(SWrongStreamVersion, hcTFWrongStreamVersion);
  end;
end;

procedure TBaseVirtualTree.AfterConstruction;

begin
  inherited;

  if FRoot = nil then
    InitRootNode;
end;

procedure TBaseVirtualTree.Assign(Source: TPersistent);

begin
  if (Source is TBaseVirtualTree) and not (toReadOnly in FOptions.FMiscOptions) then
    with Source as TBaseVirtualTree do
    begin
      Self.Align := Align;
      Self.Anchors := Anchors;
      Self.AutoScrollDelay := AutoScrollDelay;
      Self.AutoScrollInterval := AutoScrollInterval;
      Self.AutoSize := AutoSize;
      Self.Background := Background;
      Self.BevelEdges := BevelEdges;
      Self.BevelInner := BevelInner;
      Self.BevelKind := BevelKind;
      Self.BevelOuter := BevelOuter;
      Self.BevelWidth := BevelWidth;
      Self.BiDiMode := BiDiMode;
      Self.BorderStyle := BorderStyle;
      Self.BorderWidth := BorderWidth;
      Self.ChangeDelay := ChangeDelay;
      Self.CheckImageKind := CheckImageKind;
      Self.Color := Color;
      Self.Colors.Assign(Colors);
      Self.Constraints.Assign(Constraints);
      Self.Ctl3D := Ctl3D;
      Self.DefaultNodeHeight := DefaultNodeHeight;
      Self.DefaultPasteMode := DefaultPasteMode;
      Self.DragCursor := DragCursor;
      Self.DragImageKind := DragImageKind;
      Self.DragKind := DragKind;
      Self.DragMode := DragMode;
      Self.Enabled := Enabled;
      Self.Font := Font;
      Self.Header := Header;
      Self.HintAnimation := HintAnimation;
      Self.HintMode := HintMode;
      Self.HotCursor := HotCursor;
      Self.Images := Images;
      Self.ImeMode := ImeMode;
      Self.ImeName := ImeName;
      Self.Indent := Indent;
      Self.Margin := Margin;
      Self.NodeAlignment := NodeAlignment;
      Self.NodeDataSize := NodeDataSize;
      Self.TreeOptions := TreeOptions;
      Self.ParentBiDiMode := ParentBiDiMode;
      Self.ParentColor := ParentColor;
      Self.ParentCtl3D := ParentCtl3D;
      Self.ParentFont := ParentFont;
      Self.ParentShowHint := ParentShowHint;
      Self.PopupMenu := PopupMenu;
      Self.RootNodeCount := RootNodeCount;
      Self.ScrollBarOptions := ScrollBarOptions;
      Self.ShowHint := ShowHint;
      Self.StateImages := StateImages;
      Self.TabOrder := TabOrder;
      Self.TabStop := TabStop;
      Self.Visible := Visible;
      Self.SelectionCurveRadius := SelectionCurveRadius;
      Self.SelectionBlendFactor := SelectionBlendFactor;
      Self.EmptyListMessage := EmptyListMessage;
    end
    else
      inherited;
end;

procedure TBaseVirtualTree.BeginDrag(Immediate: Boolean; Threshold: Integer);

begin
  if FDragType = dtVCL then
  begin
    DoStateChange([tsVCLDragPending]);
    inherited;
  end
  else
    if (FStates * [tsOLEDragPending, tsOLEDragging]) = [] then
    begin
      
      if Threshold < 0 then
        FDragThreshold := Mouse.DragThreshold
      else
        FDragThreshold := Threshold;
      if Immediate then
        DoDragging(FLastClickPos)
      else
        DoStateChange([tsOLEDragPending]);
    end;
end;

procedure TBaseVirtualTree.BeginSynch;

begin
  if not (csDestroying in ComponentState) then
  begin
    if FSynchUpdateCount = 0 then
    begin
      DoUpdating(usBeginSynch);
      
      StopTimer(ChangeTimer);
      StopTimer(StructureChangeTimer);
      StopTimer(ExpandTimer);
      StopTimer(EditTimer);
      StopTimer(HeaderTimer);
      StopTimer(ScrollTimer);
      StopTimer(SearchTimer);
      FSearchBuffer := '';
      FLastSearchNode := nil;
      DoStateChange([], [tsEditPending, tsScrollPending, tsScrolling, tsIncrementalSearching]);
      
      if tsStructureChangePending in FStates then
        DoStructureChange(FLastStructureChangeNode, FLastStructureChangeReason);
      if tsChangePending in FStates then
        DoChange(FLastChangedNode);
    end
    else
      DoUpdating(usSynch);
  end;
  Inc(FSynchUpdateCount);
  DoStateChange([tsSynchMode]);
end;

procedure TBaseVirtualTree.BeginUpdate;

begin
  if not (csDestroying in ComponentState) then
  begin
    if FUpdateCount = 0 then
    begin
      DoUpdating(usBegin);
      SetUpdateState(True);
    end
    else
      DoUpdating(usUpdate);
  end;
  Inc(FUpdateCount);
  DoStateChange([tsUpdating]);
end;

procedure TBaseVirtualTree.CancelCutOrCopy;

var
  Run: PVirtualNode;

begin
  if ([tsCutPending, tsCopyPending] * FStates) <> [] then
  begin
    Run := FRoot.FirstChild;
    while Assigned(Run) do
    begin
      if vsCutOrCopy in Run.States then
        Exclude(Run.States, vsCutOrCopy);
      Run := GetNextNoInit(Run);
    end;
  end;
  DoStateChange([], [tsCutPending, tsCopyPending]);
end;

function TBaseVirtualTree.CancelEditNode: Boolean;

begin
  if HandleAllocated and ([tsEditing, tsEditPending] * FStates <> []) then
    Result := DoCancelEdit
  else
    Result := True;
end;

procedure TBaseVirtualTree.CancelOperation;

begin
  if FOperationCount > 0 then
    FOperationCanceled := True;
end;

function TBaseVirtualTree.CanEdit(Node: PVirtualNode; Column: TColumnIndex): Boolean;

begin
  Result := (toEditable in FOptions.FMiscOptions) and Enabled and not (toReadOnly in FOptions.FMiscOptions);
  DoCanEdit(Node, Column, Result);
end;

function TBaseVirtualTree.CanFocus: Boolean;

var
  Form: TCustomForm;

begin
  Result := inherited CanFocus;

  if Result and not (csDesigning in ComponentState) then
  begin
    Form := GetParentForm(Self);
    Result := (Form = nil) or (Form.Enabled and Form.Visible);
  end;
end;

procedure TBaseVirtualTree.Clear;

begin
  if not (toReadOnly in FOptions.FMiscOptions) or (csDestroying in ComponentState) then
  begin
    BeginUpdate;
    try
      InterruptValidation;
      if IsEditing then
        CancelEditNode;

      if ClipboardStates * FStates <> [] then
      begin
        OleSetClipBoard(nil);
        DoStateChange([], ClipboardStates);
      end;
      ClearSelection;
      FFocusedNode := nil;
      FLastSelected := nil;
      FCurrentHotNode := nil;
      FDropTargetNode := nil;
      FLastChangedNode := nil;
      FRangeAnchor := nil;
      FCheckNode := nil;
      FLastVCLDragTarget := nil;
      FLastSearchNode := nil;
      DeleteChildren(FRoot, True);
      FOffsetX := 0;
      FOffsetY := 0;

    finally
      EndUpdate;
    end;
  end;
end;

procedure TBaseVirtualTree.ClearChecked;

var
  Node: PVirtualNode;

begin
  Node := RootNode.FirstChild;
  while Assigned(Node) do
  begin
    if Node.CheckState <> csUncheckedNormal then
      CheckState[Node] := csUncheckedNormal;
    Node := GetNextNoInit(Node);
  end;
end;

procedure TBaseVirtualTree.ClearSelection;

var
  Node: PVirtualNode;
  Dummy: Integer;
  R: TRect;
  Counter: Integer;

begin
  if not FSelectionLocked and (FSelectionCount > 0) and not (csDestroying in ComponentState) then
  begin
    if (FUpdateCount = 0) and HandleAllocated and (FVisibleCount > 0) then
    begin
      
      Node := GetNodeAt(0, 0, True, Dummy);
      if Assigned(Node) then
        R := GetDisplayRect(Node, NoColumn, False);
      Counter := FSelectionCount;

      while Assigned(Node) do
      begin
        R.Bottom := R.Top + Integer(NodeHeight[Node]);
        if vsSelected in Node.States then
        begin
          InvalidateRect(Handle, @R, False);
          Dec(Counter);
          
          if Counter = 0 then
            Break;
        end;
        R.Top := R.Bottom;
        if R.Top > ClientHeight then
          Break;
        Node := GetNextVisibleNoInit(Node, True);
      end;
    end;

    InternalClearSelection;
    Change(nil);
  end;
end;

function TBaseVirtualTree.CopyTo(Source: PVirtualNode; Tree: TBaseVirtualTree; Mode: TVTNodeAttachMode;
  ChildrenOnly: Boolean): PVirtualNode;

begin
  Result := CopyTo(Source, Tree.FRoot, Mode, ChildrenOnly);
end;

function TBaseVirtualTree.CopyTo(Source, Target: PVirtualNode; Mode: TVTNodeAttachMode;
  ChildrenOnly: Boolean): PVirtualNode;

var
  TargetTree: TBaseVirtualTree;
  Stream: TMemoryStream;

begin
  Assert(TreeFromNode(Source) = Self, 'The source tree must contain the source node.');

  Result := nil;
  if (Mode <> amNoWhere) and Assigned(Source) and (Source <> FRoot) then
  begin
    
    if Target = nil then
    begin
      TargetTree := Self;
      Target := FRoot;
      Mode := amAddChildFirst;
    end
    else
      TargetTree := TreeFromNode(Target);

    if not (toReadOnly in TargetTree.FOptions.FMiscOptions) then
    begin
      if Target = TargetTree.FRoot then
      begin
        case Mode of
          amInsertBefore:
            Mode := amAddChildFirst;
          amInsertAfter:
            Mode := amAddChildLast;
        end;
      end;

      Stream := TMemoryStream.Create;
      try
        
        if not ChildrenOnly then
          WriteNode(Stream, Source)
        else
        begin
          Source := Source.FirstChild;
          while Assigned(Source) do
          begin
            WriteNode(Stream, Source);
            Source := Source.NextSibling;
          end;
        end;
        
        TargetTree.BeginUpdate;
        try
          Stream.Position := 0;
          while Stream.Position < Stream.Size do
          begin
            Result := TargetTree.MakeNewNode;
            InternalConnectNode(Result, Target, TargetTree, Mode);
            TargetTree.InternalAddFromStream(Stream, VTTreeStreamVersion, Result);
            if not DoNodeCopying(Result, Target) then
            begin
              TargetTree.DeleteNode(Result);
              Result := nil;
            end
            else
              DoNodeCopied(Result);
          end;
          if ChildrenOnly then
            Result := Target;
        finally
          TargetTree.EndUpdate;
        end;
      finally
        Stream.Free;
      end;

      with TargetTree do
      begin
        InvalidateCache;
        if FUpdateCount = 0 then
        begin
          ValidateCache;
          UpdateScrollBars(True);
          Invalidate;
        end;
        StructureChange(Source, crNodeCopied);
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.CopyToClipBoard;

var
  DataObject: IDataObject;

begin
  if FSelectionCount > 0 then
  begin
    DataObject := TVTDataObject.Create(Self, True) as IDataObject;
    if OleSetClipBoard(DataObject) = S_OK then
    begin
      MarkCutCopyNodes;
      DoStateChange([tsCopyPending]);
      Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.CutToClipBoard;
begin
  if (FSelectionCount > 0) and not (toReadOnly in FOptions.FMiscOptions) then
  begin
    if OleSetClipBoard(TVTDataObject.Create(Self, True)) = S_OK then
    begin
      MarkCutCopyNodes;
      DoStateChange([tsCutPending], [tsCopyPending]);
      Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.DeleteChildren(Node: PVirtualNode; ResetHasChildren: Boolean = False);

var
  Run,
  Mark: PVirtualNode;
  LastTop,
  LastLeft,
  NewSize: Integer;
  ParentVisible: Boolean;

begin
  if Assigned(Node) and (Node.ChildCount > 0) and not (toReadOnly in FOptions.FMiscOptions) then
  begin
    Assert(not (tsIterating in FStates), 'Deleting nodes during tree iteration leads to invalid pointers.');
    
    Inc(FUpdateCount);
    try
      InterruptValidation;
      LastLeft := -FEffectiveOffsetX;
      LastTop := FOffsetY;
      
      ParentVisible := Node = FRoot;
      if not ParentVisible then
        ParentVisible := FullyVisible[Node] and (vsExpanded in Node.States);
      
      Include(Node.States, vsClearing);
      Run := Node.LastChild;
      while Assigned(Run) do
      begin
        if ParentVisible and IsEffectivelyVisible[Run] then
          Dec(FVisibleCount);

        Include(Run.States, vsDeleting);
        Mark := Run;
        Run := Run.PrevSibling;
        
        if Assigned(Run) then
          Run.NextSibling := nil;
        DeleteNode(Mark);
      end;
      Exclude(Node.States, vsClearing);
      if ResetHasChildren then
        Exclude(Node.States, vsHasChildren);
      if Node <> FRoot then
        Exclude(Node.States, vsExpanded);
      Node.ChildCount := 0;
      if (Node = FRoot) or (vsDeleting in Node.States) then
      begin
        Node.TotalHeight := FDefaultNodeHeight + NodeHeight[Node];
        Node.TotalCount := 1;
      end
      else
      begin
        AdjustTotalHeight(Node, NodeHeight[Node]);
        AdjustTotalCount(Node, 1);
      end;
      Node.FirstChild := nil;
      Node.LastChild := nil;
    finally
      Dec(FUpdateCount);
    end;

    InvalidateCache;
    if FUpdateCount = 0 then
    begin
      NewSize := PackArray(FSelection, FSelectionCount);
      if NewSize > -1 then
      begin
        FSelectionCount := NewSize;
        SetLength(FSelection, FSelectionCount);
      end;

      ValidateCache;
      UpdateScrollbars(True);
      
      if (LastLeft <> FOffsetX) or (LastTop <> FOffsetY) then
        Invalidate
      else
        InvalidateToBottom(Node);
    end;
    StructureChange(Node, crChildDeleted);
  end
  else if ResetHasChildren then
    Exclude(Node.States, vsHasChildren);
end;

procedure TBaseVirtualTree.DeleteNode(Node: PVirtualNode; Reindex: Boolean = True);

var
  LastTop,
  LastLeft: Integer;
  LastParent: PVirtualNode;
  WasInSynchMode: Boolean;
  ParentClearing: Boolean;

begin
  if Assigned(Node) and (Node <> FRoot) and not (toReadOnly in FOptions.FMiscOptions) then
  begin
    Assert(not (tsIterating in FStates), 'Deleting nodes during tree iteration leads to invalid pointers.');
    
    ParentClearing := vsClearing in Node.Parent.States;
    LastParent := Node.Parent;

    if not ParentClearing then
    begin
      if LastParent = FRoot then
        StructureChange(nil, crChildDeleted)
      else
        StructureChange(LastParent, crChildDeleted);
    end;

    LastLeft := -FEffectiveOffsetX;
    LastTop := FOffsetY;

    if vsSelected in Node.States then
    begin
      if FUpdateCount = 0 then
      begin
        
        WasInSynchMode := tsSynchMode in FStates;
        Include(FStates, tsSynchMode);
        RemoveFromSelection(Node);
        if not WasInSynchMode then
          Exclude(FStates, tsSynchMode);
        InvalidateToBottom(LastParent);
      end
      else
        InternalRemoveFromSelection(Node);
    end
    else
      InvalidateToBottom(LastParent);

    if tsHint in FStates then
    begin
      Application.CancelHint;
      DoStateChange([], [tsHint]);
    end;

    if not ParentClearing then
      InterruptValidation;

    DeleteChildren(Node);
    InternalDisconnectNode(Node, False, Reindex);
    DoFreeNode(Node);

    if not ParentClearing then
    begin
      DetermineHiddenChildrenFlag(LastParent);
      InvalidateCache;
      if FUpdateCount = 0 then
      begin
        ValidateCache;
        UpdateScrollbars(True);
        
        if (LastLeft <> FOffsetX) or (LastTop <> FOffsetY) then
          Invalidate;
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.DeleteSelectedNodes;

var
  Nodes: TNodeArray;
  I: Integer;
  LevelChange: Boolean;

begin
  Nodes := nil;
  if (FSelectionCount > 0) and not (toReadOnly in FOptions.FMiscOptions) then
  begin
    BeginUpdate;
    try
      Nodes := GetSortedSelection(True);
      for I := High(Nodes) downto 1 do
      begin
        LevelChange := Nodes[I].Parent <> Nodes[I - 1].Parent;
        DeleteNode(Nodes[I], LevelChange);
      end;
      DeleteNode(Nodes[0]);
    finally
      EndUpdate;
    end;
  end;
end;

function TBaseVirtualTree.Dragging: Boolean;

begin
  
  Result := ([tsOLEDragPending, tsOLEDragging] * FStates <> []) or inherited Dragging;
end;

function TBaseVirtualTree.EditNode(Node: PVirtualNode; Column: TColumnIndex): Boolean;

begin
  Assert(Assigned(Node), 'Node must not be nil.');
  Assert((Column > InvalidColumn) and (Column < FHeader.Columns.Count),
    'Column must be a valid column index (-1 if no header is shown).');

  Result := tsEditing in FStates;
  
  if not Result and not (toReadOnly in FOptions.FMiscOptions) then
  begin
    FocusedNode := Node;
    if Assigned(FFocusedNode) and (Node = FFocusedNode) and CanEdit(FFocusedNode, Column) then
    begin
      FEditColumn := Column;
      if not (vsInitialized in Node.States) then
        InitNode(Node);
      DoEdit;
      Result := tsEditing in FStates;
    end
    else
      Result := False;
  end;
end;

function TBaseVirtualTree.EndEditNode: Boolean;

begin
  if [tsEditing, tsEditPending] * FStates <> [] then
    Result := DoEndEdit
  else
    Result := True;
end;

procedure TBaseVirtualTree.EndSynch;

begin
  if FSynchUpdateCount > 0 then
    Dec(FSynchUpdateCount);

  if not (csDestroying in ComponentState) then
  begin
    if FSynchUpdateCount = 0 then
    begin
      DoStateChange([], [tsSynchMode]);
      DoUpdating(usEndSynch);
    end
    else
      DoUpdating(usSynch);
  end;
end;

procedure TBaseVirtualTree.EndUpdate;

var
  NewSize: Integer;

begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if not (csDestroying in ComponentState) then
  begin
    if (FUpdateCount = 0) and (tsUpdating in FStates) then
    begin
      if tsUpdateHiddenChildrenNeeded in FStates then
      begin
        DetermineHiddenChildrenFlagAllNodes;
        Exclude(FStates, tsUpdateHiddenChildrenNeeded);
      end;

      DoStateChange([], [tsUpdating]);

      NewSize := PackArray(FSelection, FSelectionCount);
      if NewSize > -1 then
      begin
        FSelectionCount := NewSize;
        SetLength(FSelection, FSelectionCount);
      end;

      InvalidateCache;
      ValidateCache;
      if HandleAllocated then
        UpdateScrollBars(False);

      if tsStructureChangePending in FStates then
        DoStructureChange(FLastStructureChangeNode, FLastStructureChangeReason);
      try
        if tsChangePending in FStates then
          DoChange(FLastChangedNode);
      finally
        if toAutoSort in FOptions.FAutoOptions then
          SortTree(FHeader.FSortColumn, FHeader.FSortDirection, True);

        SetUpdateState(False);
        if HandleAllocated then
          Invalidate;
        UpdateDesigner;
      end;
    end;

    if FUpdateCount = 0 then
      DoUpdating(usEnd)
    else
      DoUpdating(usUpdate);
  end;
end;

function TBaseVirtualTree.ExecuteAction(Action: TBasicAction): Boolean;

begin
  Result := inherited ExecuteAction(Action);

  if not Result then
  begin
    Result := Action is TEditSelectAll;
    if Result then
      SelectAll(False)
    else
    begin
      Result := Action is TEditCopy;
      if Result then
        CopyToClipboard
      else
        if not (toReadOnly in FOptions.FMiscOptions) then
        begin
          Result := Action is TEditCut;
          if Result then
            CutToClipBoard
          else
          begin
            Result := Action is TEditPaste;
            if Result then
              PasteFromClipboard
              else
              begin
                Result := Action is TEditDelete;
                if Result then
                  DeleteSelectedNodes
              end;
          end;
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.FinishCutOrCopy;

var
  Run: PVirtualNode;

begin
  if tsCutPending in FStates then
  begin
    Run := FRoot.FirstChild;
    while Assigned(Run) do
    begin
      if vsCutOrCopy in Run.States then
        DeleteNode(Run);
      Run := GetNextNoInit(Run);
    end;
    DoStateChange([], [tsCutPending]);
  end;
end;

procedure TBaseVirtualTree.FlushClipboard;

begin
  if ClipboardStates * FStates <> [] then
  begin
    DoStateChange([tsClipboardFlushing]);
    OleFlushClipboard;
    CancelCutOrCopy;
    DoStateChange([], [tsClipboardFlushing]);
  end;
end;

procedure TBaseVirtualTree.FullCollapse(Node: PVirtualNode = nil);

var
  Stop: PVirtualNode;

begin
  if FRoot.TotalCount > 1 then
  begin
    if Node = FRoot then
      Node := nil;

    DoStateChange([tsCollapsing]);
    BeginUpdate;
    try
      Stop := Node;
      Node := GetLastVisibleNoInit(Node, True);

      if Assigned(Node) then
      begin
        repeat
          if [vsHasChildren, vsExpanded] * Node.States = [vsHasChildren, vsExpanded] then
            ToggleNode(Node);
          Node := GetPreviousNoInit(Node, True);
        until (Node = Stop) or not Assigned(Node);
        
        if Assigned(Stop) and ([vsHasChildren, vsExpanded] * Stop.States = [vsHasChildren, vsExpanded]) then
          ToggleNode(Stop);
      end;
    finally
      EndUpdate;
      DoStateChange([], [tsCollapsing]);
    end;
  end;
end;

procedure TBaseVirtualTree.FullExpand(Node: PVirtualNode = nil);

var
  Stop: PVirtualNode;

begin
  if FRoot.TotalCount > 1 then
  begin
    DoStateChange([tsExpanding]);
    BeginUpdate;
    try
      if Node = nil then
      begin
        Node := FRoot.FirstChild;
        Stop := nil;
      end
      else
      begin
        Stop := Node.NextSibling;
        if Stop = nil then
        begin
          Stop := Node;
          repeat
            Stop := Stop.Parent;
          until (Stop = FRoot) or Assigned(Stop.NextSibling);
          if Stop = FRoot then
            Stop := nil
          else
            Stop := Stop.NextSibling;
        end;
      end;
      
      if not (vsInitialized in Node.States) then
        InitNode(Node);

      repeat
        if not (vsExpanded in Node.States) then
          ToggleNode(Node);
        Node := GetNext(Node);
      until Node = Stop;
    finally
      EndUpdate;
      DoStateChange([], [tsExpanding]);
    end;
  end;
end;

function TBaseVirtualTree.GetControlsAlignment: TAlignment;

begin
  Result := FAlignment;
end;

function TBaseVirtualTree.GetDisplayRect(Node: PVirtualNode; Column: TColumnIndex; TextOnly: Boolean;
  Unclipped: Boolean = False; ApplyCellContentMargin: Boolean = False): TRect;

var
  Temp: PVirtualNode;
  Offset: Cardinal;
  CacheIsAvailable: Boolean;
  Indent,
  TextWidth: Integer;
  MainColumnHit: Boolean;
  CurrentBidiMode: TBidiMode;
  CurrentAlignment: TAlignment;
  MaxUnclippedHeight: Integer;
  TM: TTextMetric;
  ExtraVerticalMargin: Integer;

begin
  Assert(Assigned(Node), 'Node must not be nil.');
  Assert(Node <> FRoot, 'Node must not be the hidden root node.');

  MainColumnHit := (Column + 1) in [0, FHeader.MainColumn + 1];
  if not (vsInitialized in Node.States) then
    InitNode(Node);

  Result := Rect(0, 0, 0, 0);
  
  if not IsEffectivelyVisible[Node] then
    Exit;
  Temp := Node;
  Indent := 0;
  if not (toFixedIndent in FOptions.FPaintOptions) then
  begin
    while Temp <> FRoot do
    begin
      if not (vsVisible in Temp.States) or not (vsExpanded in Temp.Parent.States) then
        Exit;
      Temp := Temp.Parent;
      if MainColumnHit and (Temp <> FRoot) then
        Inc(Indent, FIndent);
    end;
  end;
  
  Offset := 0;
  CacheIsAvailable := False;
  if tsUseCache in FStates then
  begin
    
    Temp := FindInPositionCache(Node, Offset);
    CacheIsAvailable := Assigned(Temp);
    while Assigned(Temp) and (Temp <> Node) do
    begin
      Inc(Offset, NodeHeight[Temp]);
      Temp := GetNextVisibleNoInit(Temp, True);
    end;
  end;
  if not CacheIsAvailable then
  begin
    
    Temp := Node;
    repeat
      Temp := GetPreviousVisibleNoInit(Temp, True);
      if Temp = nil then
        Break;
      Inc(Offset, NodeHeight[Temp]);
    until False;
  end;

  Result := Rect(0, Offset, Max(FRangeX, ClientWidth), Offset + NodeHeight[Node]);
  
  if Column > NoColumn then
  begin
    FHeader.FColumns.GetColumnBounds(Column, Result.Left, Result.Right);
    
    Dec(Result.Right);
    OffsetRect(Result, 0, FOffsetY);
  end
  else
    OffsetRect(Result, -FEffectiveOffsetX, FOffsetY);
  
  if TextOnly then
  begin
    
    Offset := FMargin + Indent;
    
    if Column <= NoColumn then
    begin
      CurrentBidiMode := BidiMode;
      CurrentAlignment := Alignment;
    end
    else
    begin
      CurrentBidiMode := FHeader.FColumns[Column].BidiMode;
      CurrentAlignment := FHeader.FColumns[Column].Alignment;
    end;

    if MainColumnHit then
    begin
      if toShowRoot in FOptions.FPaintOptions then
        Inc(Offset, FIndent);
      if (toCheckSupport in FOptions.FMiscOptions) and Assigned(FCheckImages) and (Node.CheckType <> ctNone) then
        Inc(Offset, FCheckImages.Width + 2);
    end;
    
    if Assigned(FStateImages) and HasImage(Node, ikState, Column) then
      Inc(Offset, FStateImages.Width + 2);
    if Assigned(FImages) and HasImage(Node, ikNormal, Column) then
      Inc(Offset, GetNodeImageSize(Node).cx + 2);
    
    if CurrentBidiMode = bdLeftToRight then
    begin
      Inc(Result.Left, Offset);
      
    end
    else
    begin
      Dec(Result.Right, Offset);
      
      ChangeBiDiModeAlignment(CurrentAlignment);
    end;

    TextWidth := DoGetNodeWidth(Node, Column);
    
    MaxUnclippedHeight := Result.Bottom - Result.Top;

    if ApplyCellContentMargin then
      DoBeforeCellPaint(Self.Canvas, Node, Column, cpmGetContentMargin, Result, Result);

    if Unclipped then
    begin
      
      if Result.Right - Result.Left < TextWidth - 1 then
        if CurrentBidiMode = bdLeftToRight then
          CurrentAlignment := taLeftJustify
        else
          CurrentAlignment := taRightJustify;
      
      GetTextMetrics(Self.Canvas.Handle, TM);
      ExtraVerticalMargin := Math.Min(TM.tmHeight, MaxUnclippedHeight) - (Result.Bottom - Result.Top);
      if ExtraVerticalMargin > 0 then
        InflateRect(Result, 0, (ExtraVerticalMargin + 1) div 2);

      case CurrentAlignment of
        taCenter:
          begin
            Result.Left := (Result.Left + Result.Right - TextWidth) div 2;
            Result.Right := Result.Left + TextWidth;
          end;
        taRightJustify:
          Result.Left := Result.Right - TextWidth;
      else 
        Result.Right := Result.Left + TextWidth - 1;
      end;
    end
    else
      
      if Result.Right - Result.Left > TextWidth then
        case CurrentAlignment of
          taCenter:
            begin
              Result.Left := (Result.Left + Result.Right - TextWidth) div 2;
              Result.Right := Result.Left + TextWidth;
            end;
          taRightJustify:
            Result.Left := Result.Right - TextWidth;
        else 
          Result.Right := Result.Left + TextWidth;
        end;
  end;
end;

function TBaseVirtualTree.GetEffectivelyFiltered(Node: PVirtualNode): Boolean;

begin
  if Assigned(Node) then
    Result := (vsFiltered in Node.States) and not (toShowFilteredNodes in FOptions.FPaintOptions)
  else
    Result := False;
end;

function TBaseVirtualTree.GetEffectivelyVisible(Node: PVirtualNode): Boolean;

begin
  Result := (vsVisible in Node.States) and not IsEffectivelyFiltered[Node];
end;

function TBaseVirtualTree.GetFirst(ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
  begin
    if vsHasChildren in FRoot.States then
    begin
      Result := FRoot;
      
      if Assigned(Result.FirstChild) then
      begin
        while Assigned(Result.FirstChild) do
        begin
          Result := Result.FirstChild;
          if not (vsInitialized in Result.States) then
            InitNode(Result);

          if (vsHasChildren in Result.States) and (Result.ChildCount = 0) then
            InitChildren(Result);
        end;
      end
      else
        Result := nil;
    end
    else
      Result := nil;
  end
  else
    Result := FRoot.FirstChild;

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetFirstChecked(State: TCheckState = csCheckedNormal;
  ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  Result := GetNextChecked(nil, State, ConsiderChildrenAbove);
end;

function TBaseVirtualTree.GetFirstChild(Node: PVirtualNode): PVirtualNode;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := FRoot.FirstChild
  else
  begin
    if not (vsInitialized in Node.States) then
      InitNode(Node);
    if vsHasChildren in Node.States then
    begin
      if Node.ChildCount = 0 then
        InitChildren(Node);
      Result := Node.FirstChild;
    end
    else
      Result := nil;
  end;

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetFirstCutCopy(ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  Result := GetNextCutCopy(nil, ConsiderChildrenAbove);
end;

function TBaseVirtualTree.GetFirstInitialized(ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  Result := GetFirstNoInit(ConsiderChildrenAbove);
  if Assigned(Result) and not (vsInitialized in Result.States) then
    Result := GetNextInitialized(Result, ConsiderChildrenAbove);
end;

function TBaseVirtualTree.GetFirstLeaf: PVirtualNode;

begin
  Result := GetNextLeaf(nil);
end;

function TBaseVirtualTree.GetFirstLevel(NodeLevel: Cardinal): PVirtualNode;

begin
  Result := GetFirstNoInit(True);
  while Assigned(Result) and (GetNodeLevel(Result) <> NodeLevel) do
    Result := GetNextNoInit(Result, True);

  if Assigned(Result) and (GetNodeLevel(Result) <> NodeLevel) then 
    Result := nil;

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetFirstNoInit(ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
  begin
    if vsHasChildren in FRoot.States then
    begin
      Result := FRoot;
      
      if Assigned(Result.FirstChild) then
      begin
        while Assigned(Result.FirstChild) do
          Result := Result.FirstChild;
      end
      else
        Result := nil;
    end
    else
      Result := nil;
  end
  else
    Result := FRoot.FirstChild;
end;

function TBaseVirtualTree.GetFirstSelected(ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  Result := GetNextSelected(nil, ConsiderChildrenAbove);
end;

function TBaseVirtualTree.GetFirstVisible(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = True;
  IncludeFiltered: Boolean = False): PVirtualNode;

begin
  Result := Node;
  if not Assigned(Result) then
    Result := FRoot;

  if vsHasChildren in Result.States then
  begin
    if Result.ChildCount = 0 then
      InitChildren(Result);
    
    if Assigned(Result.FirstChild) then
    begin
      Result := GetFirstChild(Result);

      if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
      begin
        repeat
          
          while Assigned(Result.NextSibling) and not (vsVisible in Result.States) do
          begin
            Result := Result.NextSibling;
            
            if not (vsInitialized in Result.States) then
              InitNode(Result);
          end;
          
          if not (vsVisible in Result.States) then
          begin
            Result := Result.Parent;
            if Result = FRoot then
              Result := nil;
            Break;
          end
          else
          begin
            if (vsHasChildren in Result.States) and (Result.ChildCount = 0) then
              InitChildren(Result);
            if (not Assigned(Result.FirstChild)) or (not (vsExpanded in Result.States)) then
              Break;
          end;

          Result := Result.FirstChild;
          if not (vsInitialized in Result.States) then
            InitNode(Result);
        until False;
      end
      else
      begin
        
        if not (vsVisible in Result.States) then
        begin
          repeat
            
            if Assigned(Result.NextSibling) then
            begin
              Result := Result.NextSibling;
              
              if not (vsInitialized in Result.States) then
                InitNode(Result);
              if vsVisible in Result.States then
                Break;
            end
            else
            begin
              
              if Result.Parent <> FRoot then
                Result := Result.Parent
              else
              begin
                
                Result := nil;
                Break;
              end;
            end;
          until False;
        end;
      end;
    end
    else
      Result := nil;
  end
  else
    Result := nil;

  if Assigned(Result) and not IncludeFiltered and IsEffectivelyFiltered[Result] then
    Result := GetNextVisible(Result);
end;

function TBaseVirtualTree.GetFirstVisibleChild(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  if Node = nil then
    Node := FRoot;
  Result := GetFirstChild(Node);

  if Assigned(Result) and (not (vsVisible in Result.States) or
     (not IncludeFiltered and IsEffectivelyFiltered[Node])) then
    Result := GetNextVisibleSibling(Result, IncludeFiltered);
end;

function TBaseVirtualTree.GetFirstVisibleChildNoInit(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  if Node = nil then
    Node := FRoot;
  Result := Node.FirstChild;
  if Assigned(Result) and (not (vsVisible in Result.States) or
     (not IncludeFiltered and IsEffectivelyFiltered[Node])) then
    Result := GetNextVisibleSiblingNoInit(Result, IncludeFiltered);
end;

function TBaseVirtualTree.GetFirstVisibleNoInit(Node: PVirtualNode = nil;
  ConsiderChildrenAbove: Boolean = True; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  Result := Node;
  if not Assigned(Result) then
    Result := FRoot;

  if vsHasChildren in Result.States then
  begin
    
    if Assigned(Result.FirstChild) then
    begin
      Result := Result.FirstChild;

      if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
      begin
        repeat
          
          while Assigned(Result.NextSibling) and not (vsVisible in Result.States) do
            Result := Result.NextSibling;
          
          if not (vsVisible in Result.States) then
          begin
            Result := Result.Parent;
            if Result = FRoot then
              Result := nil;
            Break;
          end
          else
            if (not Assigned(Result.FirstChild)) or (not (vsExpanded in Result.States))then
              Break;

          Result := Result.FirstChild;
        until False;
      end
      else
      begin
        
        if not (vsVisible in Result.States) then
        begin
          repeat
            
            if Assigned(Result.NextSibling) then
            begin
              Result := Result.NextSibling;
              if vsVisible in Result.States then
                Break;
            end
            else
            begin
              
              if Result.Parent <> FRoot then
                Result := Result.Parent
              else
              begin
                
                Result := nil;
                Break;
              end;
            end;
          until False;
        end;
      end;
    end
    else
      Result := nil;
  end
  else
    Result := nil;

  if Assigned(Result) and not IncludeFiltered and IsEffectivelyFiltered[Result] then
    Result := GetNextVisibleNoInit(Result);
end;

procedure TBaseVirtualTree.GetHitTestInfoAt(X, Y: Integer; Relative: Boolean; var HitInfo: THitInfo);

var
  ColLeft,
  ColRight: Integer;
  NodeTop: Integer;
  InitialColumn,
  NextColumn: TColumnIndex;
  CurrentBidiMode: TBidiMode;
  CurrentAlignment: TAlignment;
  NodeRect: TRect;

begin
  HitInfo.HitNode := nil;
  HitInfo.HitPositions := [];
  HitInfo.HitColumn := NoColumn;
  
  if X < 0 then
    Include(HitInfo.HitPositions, hiToLeft)
  else
    if X > Max(FRangeX, ClientWidth) then
      Include(HitInfo.HitPositions, hiToRight);

  if Y < 0 then
    Include(HitInfo.HitPositions, hiAbove)
  else
    if Y > Max(FRangeY, ClientHeight) then
      Include(HitInfo.HitPositions, hiBelow);
  
  if Relative then
  begin
    if X >= Header.Columns.GetVisibleFixedWidth then
      Inc(X, FEffectiveOffsetX);
    Inc(Y, -FOffsetY);
  end;
  
  if HitInfo.HitPositions = [] then
  begin
    HitInfo.HitNode := GetNodeAt(X, Y, False, NodeTop);
    if HitInfo.HitNode = nil then
      Include(HitInfo.HitPositions, hiNowhere)
    else
    begin
      
      if not (vsInitialized in HitInfo.HitNode.States) then
        InitNode(HitInfo.HitNode);

      if FHeader.UseColumns then
      begin
        HitInfo.HitColumn := FHeader.Columns.GetColumnAndBounds(Point(X, Y), ColLeft, ColRight, False);
        
        if toAutoSpanColumns in FOptions.FAutoOptions then
        begin
          InitialColumn := HitInfo.HitColumn;
          
          while (HitInfo.HitColumn > NoColumn) and ColumnIsEmpty(HitInfo.HitNode, HitInfo.HitColumn) do
          begin
            NextColumn := FHeader.FColumns.GetPreviousVisibleColumn(HitInfo.HitColumn);
            if NextColumn = InvalidColumn then
              Break;
            HitInfo.HitColumn := NextColumn;
            Dec(ColLeft, FHeader.FColumns[NextColumn].Width);
          end;
          
          repeat
            InitialColumn := FHeader.FColumns.GetNextVisibleColumn(InitialColumn);
            if (InitialColumn = InvalidColumn) or not ColumnIsEmpty(HitInfo.HitNode, InitialColumn) then
              Break;
            Inc(ColRight, FHeader.FColumns[InitialColumn].Width);
          until False;
        end;
        
        Dec(X, ColLeft);
        Dec(ColRight, ColLeft);
      end
      else
      begin
        HitInfo.HitColumn := NoColumn;
        ColRight := Max(FRangeX, ClientWidth);
      end;
      ColLeft := 0;

      if HitInfo.HitColumn = InvalidColumn then
        Include(HitInfo.HitPositions, hiNowhere)
      else
      begin
        
        HitInfo.HitPositions := [hiOnItem];
        
        if toNodeHeightResize in FOptions.FMiscOptions then
        begin
          NodeRect := GetDisplayRect(HitInfo.HitNode, HitInfo.HitColumn, False);
          if Y <= (NodeRect.Top - FOffsetY + 1) then
            Include(HitInfo.HitPositions, hiUpperSplitter)
          else
          if Y >= (NodeRect.Bottom - FOffsetY - 3) then
            Include(HitInfo.HitPositions, hiLowerSplitter);
        end;

        if HitInfo.HitColumn <= NoColumn then
        begin
          CurrentBidiMode := BidiMode;
          CurrentAlignment := Alignment;
        end
        else
        begin
          CurrentBidiMode := FHeader.FColumns[HitInfo.HitColumn].BidiMode;
          CurrentAlignment := FHeader.FColumns[HitInfo.HitColumn].Alignment;
        end;

        if CurrentBidiMode = bdLeftToRight then
          DetermineHitPositionLTR(HitInfo, X, ColRight, CurrentAlignment)
        else
          DetermineHitPositionRTL(HitInfo, X, ColRight, CurrentAlignment);
      end;
    end;
  end;
end;

function TBaseVirtualTree.GetLast(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

var
  Next: PVirtualNode;

begin
  Result := GetLastChild(Node);
  if not ConsiderChildrenAbove or not (toChildrenAbove in FOptions.FPaintOptions) then
    while Assigned(Result) do
    begin
      
      Next := GetLastChild(Result);
      if Next = nil then
        Break;
      Result := Next;
    end;
end;

function TBaseVirtualTree.GetLastInitialized(Node: PVirtualNode = nil;
  ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  Result := GetLastNoInit(Node, ConsiderChildrenAbove);
  if Assigned(Result) and not (vsInitialized in Result.States) then
    Result := GetPreviousInitialized(Result, ConsiderChildrenAbove);
end;

function TBaseVirtualTree.GetLastNoInit(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

var
  Next: PVirtualNode;

begin
  Result := GetLastChildNoInit(Node);
  if not ConsiderChildrenAbove or not (toChildrenAbove in FOptions.FPaintOptions) then
    while Assigned(Result) do
    begin
      
      Next := GetLastChildNoInit(Result);
      if Next = nil then
        Break;
      Result := Next;
    end;
end;

function TBaseVirtualTree.GetLastChild(Node: PVirtualNode): PVirtualNode;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := FRoot.LastChild
  else
  begin
    if not (vsInitialized in Node.States) then
      InitNode(Node);
    if vsHasChildren in Node.States then
    begin
      if Node.ChildCount = 0 then
        InitChildren(Node);
      Result := Node.LastChild;
    end
    else
      Result := nil;
  end;

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetLastChildNoInit(Node: PVirtualNode): PVirtualNode;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := FRoot.LastChild
  else
  begin
    if vsHasChildren in Node.States then
      Result := Node.LastChild
    else
      Result := nil;
  end;
end;

function TBaseVirtualTree.GetLastVisible(Node: PVirtualNode = nil; ConsiderChildrenAbove: Boolean = True;
  IncludeFiltered: Boolean = False): PVirtualNode;

var
  Run: PVirtualNode;

begin
  Result := GetLastVisibleNoInit(Node, ConsiderChildrenAbove);

  Run := Result;
  while Assigned(Run) and (Run <> Node)  and (Run <> RootNode) do
  begin
    if not (vsInitialized in Run.States) then
      InitNode(Run);
    Run := Run.Parent;
  end;
end;

function TBaseVirtualTree.GetLastVisibleChild(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := GetLastChild(FRoot)
  else
    if FullyVisible[Node] and (vsExpanded in Node.States) then
      Result := GetLastChild(Node)
    else
      Result := nil;

  if Assigned(Result) and (not (vsVisible in Result.States) or
     (not IncludeFiltered and IsEffectivelyFiltered[Node])) then
    Result := GetPreviousVisibleSibling(Result, IncludeFiltered);

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetLastVisibleChildNoInit(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := GetLastChildNoInit(FRoot)
  else
    if FullyVisible[Node] and (vsExpanded in Node.States) then
      Result := GetLastChildNoInit(Node)
    else
      Result := nil;

  if Assigned(Result) and (not (vsVisible in Result.States) or
     (not IncludeFiltered and IsEffectivelyFiltered[Node])) then
    Result := GetPreviousVisibleSiblingNoInit(Result, IncludeFiltered);
end;

function TBaseVirtualTree.GetLastVisibleNoInit(Node: PVirtualNode = nil;
  ConsiderChildrenAbove: Boolean = True; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  Result := GetLastNoInit(Node, ConsiderChildrenAbove);
  while Assigned(Result) and (Result <> Node) do
  begin
    if FullyVisible[Result] and
       (IncludeFiltered or not IsEffectivelyFiltered[Result]) then
      Break;
    Result := GetPreviousNoInit(Result, ConsiderChildrenAbove);
  end;

  if (Result = Node) then 
    Result := nil;
end;

function TBaseVirtualTree.GetMaxColumnWidth(Column: TColumnIndex; UseSmartColumnWidth: Boolean = False): Integer;

var
  Run,
  LastNode,
  NextNode: PVirtualNode;
  NodeLeft,
  TextLeft,
  CurrentWidth: Integer;
  AssumeImage: Boolean;
  WithCheck,
  WithStateImages: Boolean;
  CheckOffset,
  StateImageOffset: Integer;

begin
  if OperationCanceled then
  begin
    
    Result := FHeader.FColumns[Column].Width;
    Exit;
  end
  else
    Result := 0;

  StartOperation(okGetMaxColumnWidth);
  try
    if Assigned(FOnBeforeGetMaxColumnWidth) then
      FOnBeforeGetMaxColumnWidth(FHeader, Column, UseSmartColumnWidth);

    WithStateImages := Assigned(FStateImages);
    if WithStateImages then
      StateImageOffset := FStateImages.Width + 2
    else
      StateImageOffset := 0;
    if Assigned(FCheckImages) then
      CheckOffset := FCheckImages.Width + 2
    else
      CheckOffset := 0;

    if UseSmartColumnWidth then 
      Run := GetTopNode
    else
      Run := GetFirstVisible(nil, True);

    if Column = FHeader.MainColumn then
    begin
      if toFixedIndent in FOptions.FPaintOptions then
        NodeLeft := FIndent
      else
      begin
        if toShowRoot in FOptions.FPaintOptions then
          NodeLeft := Integer((GetNodeLevel(Run) + 1) * FIndent)
        else
          NodeLeft := Integer(GetNodeLevel(Run) * FIndent);
      end;

      WithCheck := (toCheckSupport in FOptions.FMiscOptions) and Assigned(FCheckImages);
    end
    else
    begin
      NodeLeft := 0;
      WithCheck := False;
    end;
    
    Inc(NodeLeft, FMargin);
    
    if UseSmartColumnWidth then
      LastNode := GetNextVisible(BottomNode)
    else
      LastNode := nil;

    AssumeImage := False;
    while Assigned(Run) and not OperationCanceled do
    begin
      TextLeft := NodeLeft;
      if WithCheck and (Run.CheckType <> ctNone) then
        Inc(TextLeft, CheckOffset);
      if Assigned(fImages) and (AssumeImage or HasImage(Run, ikNormal, Column)) then begin
        TextLeft := TextLeft + GetNodeImageSize(Run).cx + 2;
        AssumeImage := True;
      end;
      if WithStateImages and HasImage(Run, ikState, Column) then
        Inc(TextLeft, StateImageOffset);

      CurrentWidth := DoGetNodeWidth(Run, Column);
      Inc(CurrentWidth, DoGetNodeExtraWidth(Run, Column));
      Inc(CurrentWidth, DoGetCellContentMargin(Run, Column).X);

      if Result < (TextLeft + CurrentWidth) then
        Result := TextLeft + CurrentWidth;
      
      NextNode := GetNextVisible(Run, True);
      if NextNode = LastNode then
        Break;
      if (Column = Header.MainColumn) and not (toFixedIndent in FOptions.FPaintOptions) then
        Inc(NodeLeft, CountLevelDifference(Run, NextNode) * Integer(FIndent));
      Run := NextNode;
    end;
    if toShowVertGridLines in FOptions.FPaintOptions then
      Inc(Result);

    if Assigned(FOnAfterGetMaxColumnWidth) then
      FOnAfterGetMaxColumnWidth(FHeader, Column, Result);

  finally
    EndOperation(okGetMaxColumnWidth);
  end;
end;

function TBaseVirtualTree.GetNext(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
    begin
      
      if not Assigned(Result.NextSibling) then
      begin
        Result := Result.Parent;
        if Result = FRoot then
        begin
          Result := nil;
        end;
      end
      else
      begin
        
        Result := Result.NextSibling;
        
        if (vsHasChildren in Result.States) and (Result.ChildCount = 0) then
          InitChildren(Result);
        
        while Assigned(Result.FirstChild) do
        begin
          Result := Result.FirstChild;
          if (vsHasChildren in Result.States) and (Result.ChildCount = 0) then
            InitChildren(Result);
        end;
      end;
    end
    else
    begin
      
      if vsHasChildren in Result.States then
      begin
        
        if Result.ChildCount = 0 then
          InitChildren(Result);
      end;
      
      if Assigned(Result.FirstChild) then
        Result := Result.FirstChild
      else
      begin
        repeat
          
          if Assigned(Result.NextSibling) then
          begin
            Result := Result.NextSibling;
            Break;
          end
          else
          begin
            
            if Result.Parent <> FRoot then
              Result := Result.Parent
            else
            begin
              
              Result := nil;
              Break;
            end;
          end;
        until False;
      end;
    end;
  end;

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetNextChecked(Node: PVirtualNode; State: TCheckState = csCheckedNormal;
  ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := GetFirstNoInit(ConsiderChildrenAbove)
  else
    Result := GetNextNoInit(Node, ConsiderChildrenAbove);

  while Assigned(Result) and (Result.CheckState <> State) do
    Result := GetNextNoInit(Result, ConsiderChildrenAbove);

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetNextChecked(Node: PVirtualNode; ConsiderChildrenAbove: Boolean): PVirtualNode;
begin
  Result := Self.GetNextChecked(Node, csCheckedNormal, ConsiderChildrenAbove);
end;

function TBaseVirtualTree.GetNextCutCopy(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  if ClipboardStates * FStates <> [] then
  begin
    if (Node = nil) or (Node = FRoot) then
      Result := GetFirstNoInit(ConsiderChildrenAbove)
    else
      Result := GetNextNoInit(Node, ConsiderChildrenAbove);
    while Assigned(Result) and not (vsCutOrCopy in Result.States) do
      Result := GetNextNoInit(Result, ConsiderChildrenAbove);
    if Assigned(Result) and not (vsInitialized in Result.States) then
      InitNode(Result);
  end
  else
    Result := nil;
end;

function TBaseVirtualTree.GetNextInitialized(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  Result := Node;
  repeat
    Result := GetNextNoInit(Result, ConsiderChildrenAbove);
  until (Result = nil) or (vsInitialized in Result.States);
end;

function TBaseVirtualTree.GetNextLeaf(Node: PVirtualNode): PVirtualNode;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := FRoot.FirstChild
  else
    Result := GetNext(Node);
  while Assigned(Result) and (vsHasChildren in Result.States) do
    Result := GetNext(Result);
  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetNextLevel(Node: PVirtualNode; NodeLevel: Cardinal): PVirtualNode;

var
  StartNodeLevel: Cardinal;

begin
  Result := nil;

  if Assigned(Node) and (Node <> FRoot) then
  begin
    StartNodeLevel := GetNodeLevel(Node);

    if StartNodeLevel < NodeLevel then
    begin
      Result := GetNext(Node);
      if Assigned(Result) and (GetNodeLevel(Result) <> NodeLevel) then
        Result := GetNextLevel(Result, NodeLevel);
    end
    else
      if StartNodeLevel = NodeLevel then
      begin
        Result := Node.NextSibling;
        if not Assigned(Result) then 
        begin
          Result := Node.Parent;
          if Assigned(Result) then
          begin
            
            while Assigned(Result) and not Assigned(Result.NextSibling) do
              Result := Result.Parent;
            if Assigned(Result) then
              Result := GetNextLevel(Result.NextSibling, NodeLevel);
          end;
        end;
      end
      else
        
        Result := GetNextLevel(Node.Parent, NodeLevel);
  end;

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetNextNoInit(Node: PVirtualNode; ConsiderChildrenAbove: Boolean): PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
    begin
      
      if not Assigned(Result.NextSibling) then
      begin
        Result := Result.Parent;
        if Result = FRoot then
        begin
          Result := nil;
        end;
      end
      else
      begin
        
        Result := Result.NextSibling;
        
        while Assigned(Result.FirstChild) do
        begin
          Result := Result.FirstChild;
        end;
      end;
    end
    else
    begin
      
      if Assigned(Result.FirstChild) then
        Result := Result.FirstChild
      else
      begin
        repeat
          
          if Assigned(Result.NextSibling) then
          begin
            Result := Result.NextSibling;
            Break;
          end
          else
          begin
            
            if Result.Parent <> FRoot then
              Result := Result.Parent
            else
            begin
              
              Result := nil;
              Break;
            end;
          end;
        until False;
      end;
    end;
  end;
end;

function TBaseVirtualTree.GetNextSelected(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  if FSelectionCount > 0 then
  begin
    if (Node = nil) or (Node = FRoot) then
      Result := GetFirstNoInit(ConsiderChildrenAbove)
    else
      Result := GetNextNoInit(Node, ConsiderChildrenAbove);
    while Assigned(Result) and not (vsSelected in Result.States) do
      Result := GetNextNoInit(Result, ConsiderChildrenAbove);
    if Assigned(Result) and not (vsInitialized in Result.States) then
      InitNode(Result);
  end
  else
    Result := nil;
end;

function TBaseVirtualTree.GetNextSibling(Node: PVirtualNode): PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    Result := Result.NextSibling;
    if Assigned(Result) and not (vsInitialized in Result.States) then
      InitNode(Result);
  end;
end;

function TBaseVirtualTree.GetNextSiblingNoInit(Node: PVirtualNode): PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    Result := Result.NextSibling;
  end;
end;

function TBaseVirtualTree.GetNextVisible(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = True): PVirtualNode;

var
  ForceSearch: Boolean;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    repeat
      
      if not FullyVisible[Result] then
        Result := GetVisibleParent(Result, True);

      if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
      begin
        repeat
          
          if not Assigned(Result.NextSibling) then
          begin
            Result := Result.Parent;
            if Result = FRoot then
            begin
              Result := nil;
              Break;
            end;

            if not (vsInitialized in Result.States) then
              InitNode(Result);
            if vsVisible in Result.States then
              Break;
          end
          else
          begin
            
            Result := Result.NextSibling;
            if not (vsInitialized in Result.States) then
              InitNode(Result);
            if not (vsVisible in Result.States) then
              Continue;
            
            while (vsExpanded in Result.States) and Assigned(Result.FirstChild) do
            begin
              Result := Result.FirstChild;
              if not (vsInitialized in Result.States) then
                InitNode(Result);
              if not (vsVisible in Result.States) then
                Break;
            end;
            
            if vsVisible in Result.States then
              Break;
          end;
        until False;
      end
      else
      begin
        
        if [vsHasChildren, vsExpanded] * Result.States = [vsHasChildren, vsExpanded] then
        begin
          
          if Result.ChildCount = 0 then
            InitChildren(Result);
        end;
        
        if (vsExpanded in Result.States) and Assigned(Result.FirstChild) then
        begin
          Result := GetFirstChild(Result);
          ForceSearch := False;
        end
        else
          ForceSearch := True;
        
        if Assigned(Result) and (ForceSearch or not (vsVisible in Result.States)) then
        begin
          repeat
            
            if Assigned(Result.NextSibling) then
            begin
              Result := Result.NextSibling;
              if not (vsInitialized in Result.States) then
                InitNode(Result);
              if vsVisible in Result.States then
                Break;
            end
            else
            begin
              
              if Result.Parent <> FRoot then
                Result := Result.Parent
              else
              begin
                
                Result := nil;
                Break;
              end;
            end;
          until False;
        end;
      end;
    until not Assigned(Result) or IsEffectivelyVisible[Result];
  end;
end;

function TBaseVirtualTree.GetNextVisibleNoInit(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = True): PVirtualNode;

var
  ForceSearch: Boolean;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    repeat
      if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
      begin
        repeat
          
          if not Assigned(Result.NextSibling) then
          begin
            Result := Result.Parent;
            if Result = FRoot then
            begin
              Result := nil;
              Break;
            end;
            if vsVisible in Result.States then
              Break;
          end
          else
          begin
            
            Result := Result.NextSibling;
            if not (vsVisible in Result.States) then
              Continue;
            
            while (vsExpanded in Result.States) and Assigned(Result.FirstChild) do
            begin
              Result := Result.FirstChild;
              if not (vsVisible in Result.States) then
                Break;
            end;
            
            if vsVisible in Result.States then
              Break;
          end;
        until False;
      end
      else
      begin
        
        if not FullyVisible[Result] then
          Result := GetVisibleParent(Result, True);
        
        if (vsExpanded in Result.States) and Assigned(Result.FirstChild) then
        begin
          Result := Result.FirstChild;
          ForceSearch := False;
        end
        else
          ForceSearch := True;
        
        if ForceSearch or not (vsVisible in Result.States) then
        begin
          repeat
            
            if Assigned(Result.NextSibling) then
            begin
              Result := Result.NextSibling;
              if vsVisible in Result.States then
                Break;
            end
            else
            begin
              
              if Result.Parent <> FRoot then
                Result := Result.Parent
              else
              begin
                
                Result := nil;
                Break;
              end;
            end;
          until False;
        end;
      end;
    until not Assigned(Result) or IsEffectivelyVisible[Result];
  end;
end;

function TBaseVirtualTree.GetNextVisibleSibling(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Invalid parameter.');

  Result := Node;
  repeat
    Result := GetNextSibling(Result);
  until not Assigned(Result) or ((vsVisible in Result.States) and
        (IncludeFiltered or not IsEffectivelyFiltered[Result]));
end;

function TBaseVirtualTree.GetNextVisibleSiblingNoInit(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Invalid parameter.');

  Result := Node;
  repeat
    Result := Result.NextSibling;
  until not Assigned(Result) or ((vsVisible in Result.States) and
       (IncludeFiltered or not IsEffectivelyFiltered[Result]));
end;

function TBaseVirtualTree.GetNodeAt(X, Y: Integer): PVirtualNode;

var
  Dummy: Integer;

begin
  Result := GetNodeAt(X, Y, True, Dummy);
end;

function TBaseVirtualTree.GetNodeAt(const P: TPoint): PVirtualNode;
begin
  Result := GetNodeAt(P.X, P.Y);
end;

function TBaseVirtualTree.GetNodeAt(X, Y: Integer; Relative: Boolean; var NodeTop: Integer): PVirtualNode;

var
  AbsolutePos,
  CurrentPos: Cardinal;

begin
  if Y < 0 then
    Y := 0;

  AbsolutePos := Y;
  if Relative then
    Inc(AbsolutePos, -FOffsetY);
  
  CurrentPos := 0;
  
  if tsUseCache in FStates then
    Result := FindInPositionCache(AbsolutePos, CurrentPos)
  else
    Result := GetFirstVisibleNoInit(nil, True);
  
  while Assigned(Result) and (Result <> FRoot) do
  begin
    if AbsolutePos < (CurrentPos + NodeHeight[Result]) then
      Break;
    Inc(CurrentPos, NodeHeight[Result]);
    Result := GetNextVisibleNoInit(Result, True);
  end;

  if Result = FRoot then
    Result := nil;
  
  if Assigned(Result) then
  begin
    NodeTop := CurrentPos;
    if Relative then
      Inc(NodeTop, FOffsetY);
  end;
end;

function TBaseVirtualTree.GetNodeData(Node: PVirtualNode): Pointer;

begin
  Assert(FNodeDataSize > 0, 'NodeDataSize not initialized.');
  if (FNodeDataSize <= 0) or (Node = nil) or (Node = FRoot) then
    Result := nil
  else begin
    Result := PByte(@Node.Data) + FTotalInternalDataSize;
    Include(Node.States, vsOnFreeNodeCallRequired); 
  end;
end;

function TBaseVirtualTree.GetNodeLevel(Node: PVirtualNode): Cardinal;

var
  Run: PVirtualNode;

begin
  Result := 0;
  if Assigned(Node) and (Node <> FRoot) then
  begin
    Run := Node.Parent;
    while Run <> FRoot do
    begin
      Run := Run.Parent;
      Inc(Result);
    end;
  end;
end;

function TBaseVirtualTree.GetPrevious(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

var
  Run: PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
    begin
      
      if (vsHasChildren in Result.States) and (Result.ChildCount = 0) then
        InitChildren(Result);
      
      if Assigned(Result.LastChild) then
        Result := Result.LastChild
      else
        if Assigned(Result.PrevSibling) then
           Result := Result.PrevSibling
      else
      begin
        
        repeat
          Result := Result.Parent;
          Run    := nil;
          if Result <> FRoot then
            Run := Result.PrevSibling
          else
            Result := nil;
        until Assigned(Run) or (Result = nil);

        if Assigned(Run) then
          Result := Run;
      end;
    end
    else
    begin
      
      if Assigned(Node.PrevSibling) then
      begin
        
        Result := GetLast(Node.PrevSibling);
        if Result = nil then
          Result := Node.PrevSibling;
      end
      else
        
        if Node.Parent <> FRoot then
          Result := Node.Parent
        else
          Result := nil;
    end;
  end;

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetPreviousChecked(Node: PVirtualNode; State: TCheckState = csCheckedNormal;
  ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := GetLastNoInit(nil, ConsiderChildrenAbove)
  else
    Result := GetPreviousNoInit(Node, ConsiderChildrenAbove);

  while Assigned(Result) and (Result.CheckState <> State) do
    Result := GetPreviousNoInit(Result, ConsiderChildrenAbove);

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetPreviousCutCopy(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  if ClipboardStates * FStates <> [] then
  begin
    if (Node = nil) or (Node = FRoot) then
      Result := GetLastNoInit(nil, ConsiderChildrenAbove)
    else
      Result := GetPreviousNoInit(Node, ConsiderChildrenAbove);
    while Assigned(Result) and not (vsCutOrCopy in Result.States) do
      Result := GetPreviousNoInit(Result, ConsiderChildrenAbove);
    if Assigned(Result) and not (vsInitialized in Result.States) then
      InitNode(Result);
  end
  else
    Result := nil;
end;

function TBaseVirtualTree.GetPreviousInitialized(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  Result := Node;
  repeat
    Result := GetPreviousNoInit(Result, ConsiderChildrenAbove);
  until (Result = nil) or (vsInitialized in Result.States);
end;

function TBaseVirtualTree.GetPreviousLeaf(Node: PVirtualNode): PVirtualNode;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := FRoot.LastChild
  else
    Result := GetPrevious(Node);
  while Assigned(Result) and (vsHasChildren in Result.States) do
    Result := GetPrevious(Result);
  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetPreviousLevel(Node: PVirtualNode; NodeLevel: Cardinal): PVirtualNode;

var
  StartNodeLevel: Cardinal;
  Run: PVirtualNode;

begin
  Result := nil;

  if Assigned(Node) and (Node <> FRoot) then
  begin
    StartNodeLevel := GetNodeLevel(Node);

    if StartNodeLevel < NodeLevel then
    begin
      Result := Node.PrevSibling;
      if Assigned(Result) then
      begin
        
        Run := Result;
        while Assigned(Run) and (GetNodeLevel(Run) < NodeLevel) do
        begin
          Result := Run;
          Run := GetLastChild(Run);
        end;
        if Assigned(Run) and (GetNodeLevel(Run) = NodeLevel) then
          Result := Run
        else
        begin
          if Assigned(Result.PrevSibling) then
            Result := GetPreviousLevel(Result, NodeLevel)
          else
            if Assigned(Result) and (Result.Parent <> FRoot) then
              Result := GetPreviousLevel(Result.Parent, NodeLevel)
          else
            Result := nil;
        end;
      end
      else
        Result := GetPreviousLevel(Node.Parent, NodeLevel);
    end
    else
      if StartNodeLevel = NodeLevel then
      begin
        Result := Node.PrevSibling;
        if not Assigned(Result) then 
        begin
          Result := Node.Parent;
          if Assigned(Result) then
            Result := GetPreviousLevel(Result, NodeLevel);
        end;
      end
      else 
        Result := GetPreviousLevel(Node.Parent, NodeLevel);
  end;

  if Assigned(Result) and not (vsInitialized in Result.States) then
    InitNode(Result);
end;

function TBaseVirtualTree.GetPreviousNoInit(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

var
  Run: PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
    begin
      
      if Assigned(Result.LastChild) then
        Result := Result.LastChild
      else
        if Assigned(Result.PrevSibling) then
          Result := Result.PrevSibling
        else
        begin
          
          repeat
            Result := Result.Parent;
            Run    := nil;
            if Result <> FRoot then
              Run := Result.PrevSibling
            else
              Result := nil;
          until Assigned(Run) or (Result = nil);

          if Assigned(Run) then
            Result := Run;
        end;
    end
    else
    begin
      
      if Assigned(Node.PrevSibling) then
      begin
        
        Result := GetLastNoInit(Node.PrevSibling);
        if Result = nil then
          Result := Node.PrevSibling;
      end
      else
        
        if Node.Parent <> FRoot then
          Result := Node.Parent
        else
          Result := nil
    end;
  end;
end;

function TBaseVirtualTree.GetPreviousSelected(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = False): PVirtualNode;

begin
  if FSelectionCount > 0 then
  begin
    if (Node = nil) or (Node = FRoot) then
      Result := FRoot.LastChild
    else
      Result := GetPreviousNoInit(Node, ConsiderChildrenAbove);
    while Assigned(Result) and not (vsSelected in Result.States) do
      Result := GetPreviousNoInit(Result, ConsiderChildrenAbove);
    if Assigned(Result) and not (vsInitialized in Result.States) then
      InitNode(Result);
  end
  else
    Result := nil;
end;

function TBaseVirtualTree.GetPreviousSibling(Node: PVirtualNode): PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    Result := Result.PrevSibling;
    if Assigned(Result) and not (vsInitialized in Result.States) then
      InitNode(Result);
  end;
end;

function TBaseVirtualTree.GetPreviousSiblingNoInit(Node: PVirtualNode): PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    Result := Result.PrevSibling;
  end;
end;

function TBaseVirtualTree.GetPreviousVisible(Node: PVirtualNode; ConsiderChildrenAbove: Boolean = True): PVirtualNode;

var
  Marker: PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    repeat
      
      if not FullyVisible[Result] then
      begin
        Result := GetVisibleParent(Result, True);
        if Result = FRoot then
          Result := nil;
        Marker := GetLastVisible(Result, True);
        if Assigned(Marker) then
          Result := Marker;
      end
      else
      begin
        if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
        begin
          repeat
            if Assigned(Result.LastChild) and (vsExpanded in Result.States) then
            begin
              Result := Result.LastChild;
              if not (vsInitialized in Result.States) then
                InitNode(Result);

              if vsVisible in Result.States then
                Break;
            end
            else
              if Assigned(Result.PrevSibling) then
              begin
                if not (vsInitialized in Result.PrevSibling.States) then
                  InitNode(Result.PrevSibling);

                if vsVisible in Result.PrevSibling.States then
                begin
                  Result := Result.PrevSibling;
                  Break;
                end;
              end
              else
              begin
                Marker := nil;
                repeat
                  Result := Result.Parent;
                  if Result <> FRoot then
                    Marker := GetPreviousVisibleSibling(Result, True)
                  else
                    Result := nil;
                until Assigned(Marker) or (Result = nil);
                if Assigned(Marker) then
                  Result := Marker;

                Break;
              end;
          until False;
        end
        else
        begin
          repeat
            
            if Assigned(Result.PrevSibling) then
            begin
              Result := Result.PrevSibling;
              
              if not (vsInitialized in Result.States) then
                InitNode(Result);
              if vsVisible in Result.States then
              begin
                
                Marker := GetLastVisible(Result, True, True);
                if Assigned(Marker) then
                  Result := Marker;
                Break;
              end;
            end
            else
            begin
              
              Result := Result.Parent;
              if Result = FRoot then
                Result := nil;
              Break;
            end;
          until False;
        end;

        if Assigned(Result) and not (vsInitialized in Result.States) then
          InitNode(Result);
      end;
    until not Assigned(Result) or IsEffectivelyVisible[Result];
  end;
end;

function TBaseVirtualTree.GetPreviousVisibleNoInit(Node: PVirtualNode;
  ConsiderChildrenAbove: Boolean = True): PVirtualNode;

var
  Marker: PVirtualNode;

begin
  Result := Node;
  if Assigned(Result) then
  begin
    Assert(Result <> FRoot, 'Node must not be the hidden root node.');

    repeat
      
      if not FullyVisible[Result] then
      begin
        Result := GetVisibleParent(Result, True);
        if Result = FRoot then
          Result := nil;
        Marker := GetLastVisibleNoInit(Result, True);
        if Assigned(Marker) then
          Result := Marker;
      end
      else
      begin
        if ConsiderChildrenAbove and (toChildrenAbove in FOptions.FPaintOptions) then
        begin
          repeat
            
            if (vsExpanded in Result.States) and Assigned(Result.LastChild) then
            begin
              Result := Result.LastChild;
              if vsVisible in Result.States then
                Break;
            end
            else
              if Assigned(Result.PrevSibling) then
              begin
                
                if vsVisible in Result.PrevSibling.States then
                begin
                  Result := Result.PrevSibling;
                  Break;
                end;
              end
              else
              begin
                
                Marker := nil;
                repeat
                  Result := Result.Parent;
                  if Result <> FRoot then
                    Marker := GetPreviousVisibleSiblingNoInit(Result, True)
                  else
                    Result := nil;
                until Assigned(Marker) or (Result = nil);
                if Assigned(Marker) then
                  Result := Marker;
                Break;
              end;
          until False;
        end
        else
        begin
          repeat
            
            if Assigned(Result.PrevSibling) then
            begin
              Result := Result.PrevSibling;
              if vsVisible in Result.States then
              begin
                
                Marker := GetLastVisibleNoInit(Result, True, True);
                if Assigned(Marker) then
                  Result := Marker;
                Break;
              end;
            end
            else
            begin
              
              Result := Result.Parent;
              if Result = FRoot then
                Result := nil;
              Break;
            end;
          until False;
        end;
      end;
    until not Assigned(Result) or IsEffectivelyVisible[Result];
  end;
end;

function TBaseVirtualTree.GetPreviousVisibleSibling(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Invalid parameter.');

  Result := Node;
  repeat
    Result := GetPreviousSibling(Result);
  until not Assigned(Result) or ((vsVisible in Result.States) and
        (IncludeFiltered or not IsEffectivelyFiltered[Result]));
end;

function TBaseVirtualTree.GetPreviousVisibleSiblingNoInit(Node: PVirtualNode;
  IncludeFiltered: Boolean = False): PVirtualNode;

begin
  Assert(Assigned(Node) and (Node <> FRoot), 'Invalid parameter.');

  Result := Node;
  repeat
    Result := Result.PrevSibling;
  until not Assigned(Result) or ((vsVisible in Result.States) and
        (IncludeFiltered or not IsEffectivelyFiltered[Result]));
end;

function TBaseVirtualTree.Nodes(ConsiderChildrenAbove: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneAll;
  Result.FTree := Self;
  Result.FConsiderChildrenAbove := ConsiderChildrenAbove;
end;

function TBaseVirtualTree.CheckedNodes(State: TCheckState; ConsiderChildrenAbove: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneChecked;
  Result.FTree := Self;
  Result.FState := State;
  Result.FConsiderChildrenAbove := ConsiderChildrenAbove;
end;

function TBaseVirtualTree.ChildNodes(Node: PVirtualNode): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneChild;
  Result.FTree := Self;
  Result.FNode := Node;
end;

function TBaseVirtualTree.CutCopyNodes(ConsiderChildrenAbove: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneCutCopy;
  Result.FTree := Self;
  Result.FConsiderChildrenAbove := ConsiderChildrenAbove;
end;

function TBaseVirtualTree.InitializedNodes(ConsiderChildrenAbove: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneInitialized;
  Result.FTree := Self;
  Result.FConsiderChildrenAbove := ConsiderChildrenAbove;
end;

function TBaseVirtualTree.LeafNodes: TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneLeaf;
  Result.FTree := Self;
end;

function TBaseVirtualTree.LevelNodes(NodeLevel: Cardinal): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneLevel;
  Result.FTree := Self;
  Result.FNodeLevel := NodeLevel;
end;

function TBaseVirtualTree.NoInitNodes(ConsiderChildrenAbove: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneNoInit;
  Result.FTree := Self;
  Result.FConsiderChildrenAbove := ConsiderChildrenAbove;
end;

function TBaseVirtualTree.SelectedNodes(ConsiderChildrenAbove: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneSelected;
  Result.FTree := Self;
  Result.FConsiderChildrenAbove := ConsiderChildrenAbove;
end;

function TBaseVirtualTree.VisibleNodes(Node: PVirtualNode; ConsiderChildrenAbove: Boolean;
  IncludeFiltered: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneVisible;
  Result.FTree := Self;
  Result.FNode := Node;
  Result.FConsiderChildrenAbove := ConsiderChildrenAbove;
  Result.FIncludeFiltered := IncludeFiltered;
end;

function TBaseVirtualTree.VisibleChildNodes(Node: PVirtualNode; IncludeFiltered: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneVisibleChild;
  Result.FTree := Self;
  Result.FNode := Node;
  Result.FIncludeFiltered := IncludeFiltered;
end;

function TBaseVirtualTree.VisibleChildNoInitNodes(Node: PVirtualNode; IncludeFiltered: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneVisibleNoInitChild;
  Result.FTree := Self;
  Result.FNode := Node;
  Result.FIncludeFiltered := IncludeFiltered;
end;

function TBaseVirtualTree.VisibleNoInitNodes(Node: PVirtualNode; ConsiderChildrenAbove: Boolean;
  IncludeFiltered: Boolean): TVTVirtualNodeEnumeration;

begin
  Result.FMode := vneVisibleNoInit;
  Result.FTree := Self;
  Result.FNode := Node;
  Result.FConsiderChildrenAbove := ConsiderChildrenAbove;
  Result.FIncludeFiltered := IncludeFiltered;
end;

function TBaseVirtualTree.GetSortedCutCopySet(Resolve: Boolean): TNodeArray;

var
  Run: PVirtualNode;
  Counter: Cardinal;

  procedure IncludeThisNode(Node: PVirtualNode);

  var
    Len: Cardinal;

  begin
    Len := Length(Result);
    if Counter = Len then
    begin
      if Len < 100 then
        Len := 100
      else
        Len := Len + Len div 10;
      SetLength(Result, Len);
    end;
    Result[Counter] := Node;
    Inc(Counter);
  end;

begin
  Run := FRoot.FirstChild;
  Counter := 0;
  if Resolve then
  begin
    
    while Assigned(Run) do
    begin
      if vsCutOrCopy in Run.States then
      begin
        IncludeThisNode(Run);
        if Assigned(Run.NextSibling) then
          Run := Run.NextSibling
        else
        begin
          
          repeat
            Run := Run.Parent;
          until (Run = FRoot) or Assigned(Run.NextSibling);
          if Run = FRoot then
            Break
          else
            Run := Run.NextSibling;
        end;
      end
      else
        Run := GetNextNoInit(Run);
    end;
  end
  else
    while Assigned(Run) do
    begin
      if vsCutOrCopy in Run.States then
        IncludeThisNode(Run);
      Run := GetNextNoInit(Run);
    end;
  
  SetLength(Result, Counter);
end;

function TBaseVirtualTree.GetSortedSelection(Resolve: Boolean): TNodeArray;

var
  Run: PVirtualNode;
  Counter: Cardinal;

begin
  SetLength(Result, FSelectionCount);
  if FSelectionCount > 0 then
  begin
    Run := FRoot.FirstChild;
    Counter := 0;
    if Resolve then
    begin
      
      while Assigned(Run) do
      begin
        if vsSelected in Run.States then
        begin
          Result[Counter] := Run;
          Inc(Counter);
          if Assigned(Run.NextSibling) then
            Run := Run.NextSibling
          else
          begin
            
            repeat
              Run := Run.Parent;
            until (Run = FRoot) or Assigned(Run.NextSibling);
            if Run = FRoot then
              Break
            else
              Run := Run.NextSibling;
          end;
        end
        else
          Run := GetNextNoInit(Run);
      end;
    end
    else
      while Assigned(Run) do
      begin
        if vsSelected in Run.States then
        begin
          Result[Counter] := Run;
          Inc(Counter);
        end;
        Run := GetNextNoInit(Run);
      end;
    
    if Integer(Counter) < Length(Result) then
      SetLength(Result, Counter);
  end;
end;

procedure TBaseVirtualTree.GetTextInfo(Node: PVirtualNode; Column: TColumnIndex; const AFont: TFont; var R: TRect;
  var Text: UnicodeString);

begin
  R := Rect(0, 0, 0, 0);
  Text := '';
  AFont.Assign(Font);
end;

function TBaseVirtualTree.GetTreeRect: TRect;

begin
  Result := Rect(0, 0, Max(FRangeX, ClientWidth), Max(FRangeY, ClientHeight));
end;

function TBaseVirtualTree.GetVisibleParent(Node: PVirtualNode; IncludeFiltered: Boolean = False): PVirtualNode;

begin
  Assert(Assigned(Node), 'Node must not be nil.');
  Assert(Node <> FRoot, 'Node must not be the hidden root node.');

  Result := Node.Parent;
  while (Result <> FRoot) and (not FullyVisible[Result] or (not IncludeFiltered and IsEffectivelyFiltered[Result])) do
    Result := Result.Parent;
end;

function TBaseVirtualTree.HasAsParent(Node, PotentialParent: PVirtualNode): Boolean;

var
  Run: PVirtualNode;

begin
  Result := Assigned(Node) and Assigned(PotentialParent) and (Node <> PotentialParent);
  if Result then
  begin
    Run := Node;
    while (Run <> FRoot) and (Run <> PotentialParent) do
      Run := Run.Parent;
    Result := Run = PotentialParent;
  end;
end;

function TBaseVirtualTree.InsertNode(Node: PVirtualNode; Mode: TVTNodeAttachMode; UserData: Pointer = nil): PVirtualNode;

var
  NodeData: ^Pointer;

begin
  if Mode <> amNoWhere then
  begin
    CancelEditNode;

    if Node = nil then
      Node := FRoot;
    
    Result := MakeNewNode;
    
    if Node = FRoot then
    begin
      case Mode of
        amInsertBefore:
          Mode := amAddChildFirst;
        amInsertAfter:
          Mode := amAddChildLast;
      end;
    end;
    
    if (Mode in [amAddChildFirst, amAddChildLast]) and not (vsInitialized in Node.States) then
      InitNode(Node);
    InternalConnectNode(Result, Node, Self, Mode);
    
    if Assigned(UserData) then
      if FNodeDataSize >= sizeof(Pointer) then
      begin
        NodeData := Pointer(PByte(@Result.Data) + FTotalInternalDataSize);
        NodeData^ := UserData;
        Include(Result.States, vsOnFreeNodeCallRequired);
      end
      else
        ShowError(SCannotSetUserData, hcTFCannotSetUserData);

    if FUpdateCount = 0 then
    begin
      
      if (toAutoSort in FOptions.FAutoOptions) and (FHeader.FSortColumn > InvalidColumn) then
        case Mode of
          amInsertBefore,
          amInsertAfter:
            
            Sort(Node.Parent, FHeader.FSortColumn, FHeader.FSortDirection, True);
          amAddChildFirst,
          amAddChildLast:
            Sort(Node, FHeader.FSortColumn, FHeader.FSortDirection, True);
        end;

      UpdateScrollbars(True);
      if Mode = amInsertBefore then
        InvalidateToBottom(Result)
      else
        InvalidateToBottom(Node);
    end;
    StructureChange(Result, crNodeAdded);
  end
  else
    Result := nil;
end;

procedure TBaseVirtualTree.InvalidateChildren(Node: PVirtualNode; Recursive: Boolean);

var
  Run: PVirtualNode;

begin
  if Assigned(Node) then
  begin
    if not (vsInitialized in Node.States) then
      InitNode(Node);
    InvalidateNode(Node);
    if (vsHasChildren in Node.States) and (Node.ChildCount = 0) then
      InitChildren(Node);
    Run := Node.FirstChild;
  end
  else
    Run := FRoot.FirstChild;

  while Assigned(Run) do
  begin
    InvalidateNode(Run);
    if Recursive then
      InvalidateChildren(Run, True);
    Run := Run.NextSibling;
  end;
end;

procedure TBaseVirtualTree.InvalidateColumn(Column: TColumnIndex);

var
  R: TRect;

begin
  if (FUpdateCount = 0) and HandleAllocated and FHeader.FColumns.IsValidColumn(Column) then
  begin
    R := ClientRect;
    FHeader.Columns.GetColumnBounds(Column, R.Left, R.Right);
    InvalidateRect(Handle, @R, False);
  end;
end;

function TBaseVirtualTree.InvalidateNode(Node: PVirtualNode): TRect;

begin
  if (FUpdateCount = 0) and HandleAllocated then
  begin
    Result := GetDisplayRect(Node, NoColumn, False);
    InvalidateRect(Handle, @Result, False);
  end;
end;

procedure TBaseVirtualTree.InvalidateToBottom(Node: PVirtualNode);

var
  R: TRect;

begin
  if (FUpdateCount = 0) and HandleAllocated then
  begin
    if (Node = nil) or (Node = FRoot) then
      Invalidate
    else
      if (vsInitialized in Node.States) and IsEffectivelyVisible[Node] then
      begin
        R := GetDisplayRect(Node, -1, False);
        if R.Top < ClientHeight then
        begin
          if (toChildrenAbove in FOptions.FPaintOptions) and (vsExpanded in Node.States) then
            Dec(R.Top, Node.TotalHeight + NodeHeight[Node]);
          R.Bottom := ClientHeight;
          InvalidateRect(Handle, @R, False);
        end;
      end;
  end;
end;

procedure TBaseVirtualTree.InvertSelection(VisibleOnly: Boolean);

var
  Run: PVirtualNode;
  NewSize: Integer;
  NextFunction: TGetNextNodeProc;
  TriggerChange: Boolean;

begin
  if not FSelectionLocked and (toMultiSelect in FOptions.FSelectionOptions) then
  begin
    Run := FRoot.FirstChild;
    ClearTempCache;
    if VisibleOnly then
      NextFunction := GetNextVisibleNoInit
    else
      NextFunction := GetNextNoInit;
    while Assigned(Run) do
    begin
      if vsSelected in Run.States then
        InternalRemoveFromSelection(Run)
      else
        InternalCacheNode(Run);
      Run := NextFunction(Run);
    end;
    
    TriggerChange := False;
    NewSize := PackArray(FSelection, FSelectionCount);
    if NewSize > -1 then
    begin
      FSelectionCount := NewSize;
      SetLength(FSelection, FSelectionCount);
      TriggerChange := True;
    end;
    if FTempNodeCount > 0 then
    begin
      AddToSelection(FTempNodeCache, FTempNodeCount);
      ClearTempCache;
      TriggerChange := False;
    end;
    Invalidate;
    if TriggerChange then
      Change(nil);
  end;
end;

function TBaseVirtualTree.IsEditing: Boolean;

begin
  Result := tsEditing in FStates;
end;

function TBaseVirtualTree.IsMouseSelecting: Boolean;

begin
  Result := (tsDrawSelPending in FStates) or (tsDrawSelecting in FStates);
end;

function TBaseVirtualTree.IterateSubtree(Node: PVirtualNode; Callback: TVTGetNodeProc; Data: Pointer;
  Filter: TVirtualNodeStates = []; DoInit: Boolean = False; ChildNodesOnly: Boolean = False): PVirtualNode;

var
  Stop: PVirtualNode;
  Abort: Boolean;
  GetNextNode: TGetNextNodeProc;
  WasIterating: Boolean;

begin
  Assert(Node <> FRoot, 'Node must not be the hidden root node.');

  WasIterating := tsIterating in FStates;
  DoStateChange([tsIterating]);
  try
    
    if DoInit then
      GetNextNode := GetNext
    else
      GetNextNode := GetNextNoInit;

    Abort := False;
    if Node = nil then
      Stop := nil
    else
    begin
      if not (vsInitialized in Node.States) and DoInit then
        InitNode(Node);
      
      Stop := Node.NextSibling;
      if Stop = nil then
      begin
        Stop := Node;
        repeat
          Stop := Stop.Parent;
        until (Stop = FRoot) or Assigned(Stop.NextSibling);
        if Stop = FRoot then
          Stop := nil
        else
          Stop := Stop.NextSibling;
      end;
    end;
    
    if Node = nil then
      Node := GetFirstNoInit;

    if Assigned(Node) then
    begin
      if not (vsInitialized in Node.States) and DoInit then
        InitNode(Node);
      
      if ChildNodesOnly then
      begin
        if Node.ChildCount = 0 then
          Node := nil
        else
          Node := GetNextNode(Node);
      end;

      if Filter = [] then
      begin
        
        while Assigned(Node) and (Node <> Stop) do
        begin
          Callback(Self, Node, Data, Abort);
          if Abort then
            Break;
          Node := GetNextNode(Node);
        end;
      end
      else
      begin
        
        while Assigned(Node) and (Node <> Stop) do
        begin
          if Node.States * Filter = Filter then
            Callback(Self, Node, Data, Abort);
          if Abort then
            Break;
          Node := GetNextNode(Node)
        end;
      end;
    end;

    if Abort then
      Result := Node
    else
      Result := nil;
  finally
    if not WasIterating then
      DoStateChange([], [tsIterating]);
  end;
end;

procedure TBaseVirtualTree.LoadFromFile(const FileName: TFileName);

var
  FileStream: TFileStream;

begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TBaseVirtualTree.LoadFromStream(Stream: TStream);

var
  ThisID: TMagicID;
  Version,
  Count: Cardinal;
  Node: PVirtualNode;

begin
  if not (toReadOnly in FOptions.FMiscOptions) then
  begin
    Clear;
    
    if Stream.Read(ThisID, SizeOf(TMagicID)) < SizeOf(TMagicID) then
      ShowError(SStreamTooSmall, hcTFStreamTooSmall);

    if (ThisID[0] = MagicID[0]) and
       (ThisID[1] = MagicID[1]) and
       (ThisID[2] = MagicID[2]) and
       (ThisID[5] = MagicID[5]) then
    begin
      Version := Word(ThisID[3]);
      if Version <= VTTreeStreamVersion then
      begin
        BeginUpdate;
        try
          if Version < 2 then
            Count := MaxInt
          else
            Stream.ReadBuffer(Count, SizeOf(Count));

          while (Stream.Position < Stream.Size) and (Count > 0) do
          begin
            Dec(Count);
            Node := MakeNewNode;
            InternalConnectNode(Node, FRoot, Self, amAddChildLast);
            InternalAddFromStream(Stream, Version, Node);
          end;
          DoNodeCopied(nil);
          if Assigned(FOnLoadTree) then
            FOnLoadTree(Self, Stream);
        finally
          EndUpdate;
        end;
      end
      else
        ShowError(SWrongStreamVersion, hcTFWrongStreamVersion);
    end
    else
      ShowError(SWrongStreamFormat, hcTFWrongStreamFormat);
  end;
end;

procedure TBaseVirtualTree.MeasureItemHeight(const Canvas: TCanvas; Node: PVirtualNode);

var
  NewNodeHeight: Integer;

begin
  if not (vsHeightMeasured in Node.States) {$if CompilerVersion < 20}and (MainThreadId = GetCurrentThreadId){$ifend} then
  begin
    Include(Node.States, vsHeightMeasured);
    if (toVariableNodeHeight in FOptions.FMiscOptions) then begin
      NewNodeHeight := Node.NodeHeight;
      {$if CompilerVersion > 20} 
      if (MainThreadId <> GetCurrentThreadId) then
        TThread.Synchronize(nil, procedure begin DoMeasureItem(Canvas, Node, NewNodeHeight) end)
      else
      {$ifend}
        DoMeasureItem(Canvas, Node, NewNodeHeight);
      if NewNodeHeight <> Node.NodeHeight then
        SetNodeHeight(Node, NewNodeHeight);
    end;
  end;
end;

procedure TBaseVirtualTree.MoveTo(Node: PVirtualNode; Tree: TBaseVirtualTree; Mode: TVTNodeAttachMode;
  ChildrenOnly: Boolean);

begin
  MoveTo(Node, Tree.FRoot, Mode, ChildrenOnly);
end;

procedure TBaseVirtualTree.MoveTo(Source, Target: PVirtualNode; Mode: TVTNodeAttachMode; ChildrenOnly: Boolean);

var
  TargetTree: TBaseVirtualTree;
  Allowed: Boolean;
  NewNode: PVirtualNode;
  Stream: TMemoryStream;

begin
  Assert(TreeFromNode(Source) = Self, 'The source tree must contain the source node.');
  
  Allowed := (Source <> Target) or ((Mode in [amInsertBefore, amInsertAfter]) and ChildrenOnly);

  if Allowed and (Mode <> amNoWhere) and Assigned(Source) and (Source <> FRoot) and
    not (toReadOnly in FOptions.FMiscOptions) then
  begin
    
    if Target = nil then
    begin
      TargetTree := Self;
      Target := FRoot;
      Mode := amAddChildFirst;
    end
    else
      TargetTree := TreeFromNode(Target);

    if Target = TargetTree.FRoot then
    begin
      case Mode of
        amInsertBefore:
          Mode := amAddChildFirst;
        amInsertAfter:
          Mode := amAddChildLast;
      end;
    end;
    
    if not (vsInitialized in Target.States) then
      TargetTree.InitNode(Target)
    else
      if (vsHasChildren in Target.States) and (Target.ChildCount = 0) then
        TargetTree.InitChildren(Target);

    if TargetTree = Self then
    begin
      
      if Target = FRoot then
        Allowed := DoNodeMoving(Source, nil)
      else
        Allowed := DoNodeMoving(Source, Target);
      if Allowed then
      begin
        
        if (Source <> Target) and HasAsParent(Target, Source) then
            ShowError(SWrongMoveError, hcTFWrongMoveError);

        if not ChildrenOnly then
        begin
          
          InternalDisconnectNode(Source, True);
          
          InternalConnectNode(Source, Target, Self, Mode);
          DoNodeMoved(Source);
        end
        else
        begin
          
          if Mode = amAddChildFirst then
          begin
            Source := Source.LastChild;
            while Assigned(Source) do
            begin
              NewNode := Source.PrevSibling;
              
              InternalDisconnectNode(Source, True, False);
              
              InternalConnectNode(Source, Target, Self, Mode);
              DoNodeMoved(Source);
              Source := NewNode;
            end;
          end
          else
          begin
            Source := Source.FirstChild;
            while Assigned(Source) do
            begin
              NewNode := Source.NextSibling;
              
              InternalDisconnectNode(Source, True, False);
              
              InternalConnectNode(Source, Target, Self, Mode);
              DoNodeMoved(Source);
              Source := NewNode;
            end;
          end;
        end;
      end;
    end
    else
    begin
      
      if Target = TargetTree.FRoot then
        Allowed := DoNodeMoving(Source, nil)
      else
        Allowed := DoNodeMoving(Source, Target);

      if Allowed then
      begin
        Stream := TMemoryStream.Create;
        try
          
          if not ChildrenOnly then
            WriteNode(Stream, Source)
          else
          begin
            Source := Source.FirstChild;
            while Assigned(Source) do
            begin
              WriteNode(Stream, Source);
              Source := Source.NextSibling;
            end;
          end;
          
          TargetTree.BeginUpdate;
          try
            Stream.Position := 0;
            while Stream.Position < Stream.Size do
            begin
              NewNode := TargetTree.MakeNewNode;
              InternalConnectNode(NewNode, Target, TargetTree, Mode);
              TargetTree.InternalAddFromStream(Stream, VTTreeStreamVersion, NewNode);
              DoNodeMoved(NewNode);
            end;
          finally
            TargetTree.EndUpdate;
          end;
        finally
          Stream.Free;
        end;
        
        BeginUpdate;
        try
          if ChildrenOnly then
            DeleteChildren(Source)
          else
            DeleteNode(Source);
        finally
          EndUpdate;
        end;
      end;
    end;

    InvalidateCache;
    if (FUpdateCount = 0) and Allowed then
    begin
      ValidateCache;
      UpdateScrollBars(True);
      Invalidate;
      if TargetTree <> Self then
        TargetTree.Invalidate;
    end;
    StructureChange(Source, crNodeMoved);
  end;
end;

procedure TBaseVirtualTree.PaintTree(TargetCanvas: TCanvas; Window: TRect; Target: TPoint;
  PaintOptions: TVTInternalPaintOptions; PixelFormat: TPixelFormat);

const
  ImageKind: array[Boolean] of TVTImageKind = (ikNormal, ikSelected);

var
  DrawSelectionRect,
  UseBackground,
  ShowImages,
  ShowStateImages,
  ShowCheckImages,
  UseColumns,
  IsMainColumn: Boolean;

  VAlign,
  IndentSize,
  ButtonX,
  ButtonY: Integer;
  LineImage: TLineImage;
  PaintInfo: TVTPaintInfo;     

  R,                           
  TargetRect,                  
  SelectionRect,               
  ClipRect: TRect;             
  NextColumn: TColumnIndex;
  BaseOffset: Integer;         
  NodeBitmap: TBitmap;         
  MaximumRight,                
  MaximumBottom: Integer;      
  SelectLevel: Integer;        
  FirstColumn: TColumnIndex;   

  MaxRight,
  ColLeft,
  ColRight: Integer;

  SavedTargetDC: Integer;
  PaintWidth: Integer;
  CurrentNodeHeight: Integer;

begin
  if not (tsPainting in FStates) then
  begin
    DoStateChange([tsPainting]);
    try
      DoBeforePaint(TargetCanvas);

      if poUnbuffered in PaintOptions then
        SavedTargetDC := SaveDC(TargetCanvas.Handle)
      else
        SavedTargetDC := 0;
      
      ZeroMemory(@PaintInfo, SizeOf(PaintInfo));

      PaintWidth := Window.Right - Window.Left;

      if not (poUnbuffered in PaintOptions) then
      begin
        
        NodeBitmap := TBitmap.Create;
        
        if MMXAvailable and ((FDrawSelectionMode = smBlendedRectangle) or (tsUseThemes in FStates) or
          (toUseBlendedSelection in FOptions.PaintOptions)) then
          NodeBitmap.PixelFormat := pf32Bit
        else
          NodeBitmap.PixelFormat := PixelFormat;

        NodeBitmap.Width := PaintWidth;
        
        SetMapMode(NodeBitmap.Canvas.Handle, GetMapMode(TargetCanvas.Handle));
        PaintInfo.Canvas := NodeBitmap.Canvas;
      end
      else
      begin
        PaintInfo.Canvas := TargetCanvas;
        NodeBitmap := nil;
      end;
      
      PaintInfo.Canvas.Lock;
      try
        
        SelectionRect := OrderRect(FNewSelRect);
        DrawSelectionRect := IsMouseSelecting and not IsRectEmpty(SelectionRect) and (GetKeyState(VK_LBUTTON) < 0);
        
        R := Rect(0, 0, Max(FRangeX, ClientWidth), 0);
        
        UseBackground := (toShowBackground in FOptions.FPaintOptions) and (FBackground.Graphic is TBitmap) and
          (poBackground in PaintOptions);
        ShowImages := Assigned(FImages);
        ShowStateImages := Assigned(FStateImages);
        ShowCheckImages := Assigned(FCheckImages) and (toCheckSupport in FOptions.FMiscOptions);
        UseColumns := FHeader.UseColumns;
        
        if (toAlwaysHideSelection in FOptions.FPaintOptions) or
          (not Focused and (toHideSelection in FOptions.FPaintOptions)) then
          Exclude(PaintOptions, poDrawSelection);
        if toHideFocusRect in FOptions.FPaintOptions then
          Exclude(PaintOptions, poDrawFocusRect);
        
        BaseOffset := 0;
        PaintInfo.Node := GetNodeAt(0, Window.Top, False, BaseOffset);
        if PaintInfo.Node = nil then
          BaseOffset := Window.Top;
        
        if DrawSelectionRect then
          OffsetRect(SelectionRect, 0, -BaseOffset);
        
        MaximumRight := Target.X + (Window.Right - Window.Left);
        MaximumBottom := Target.Y + (Window.Bottom - Window.Top);

        TargetRect := Rect(Target.X, Target.Y - (Window.Top - BaseOffset), MaximumRight, 0);
        TargetRect.Bottom := TargetRect.Top;
        TargetCanvas.Font := Self.Font;
        
        FirstColumn := InvalidColumn;

        if Assigned(PaintInfo.Node) then
        begin
          ButtonX := Round((Integer(FIndent) - FPlusBM.Width) / 2) + 1;
          
          while Assigned(PaintInfo.Node) do
          begin
            
            SelectLevel := DetermineLineImageAndSelectLevel(PaintInfo.Node, LineImage);
            IndentSize := Length(LineImage);
            if not (toFixedIndent in FOptions.FPaintOptions) then
              ButtonX := (IndentSize - 1) * Integer(FIndent) + Round((Integer(FIndent) - FPlusBM.Width) / 2) + 1;
            
            if not (vsInitialized in PaintInfo.Node.States) then
              InitNode(PaintInfo.Node);
            if (vsSelected in PaintInfo.Node.States) and not (toChildrenAbove in FOptions.FPaintOptions) then
              Inc(SelectLevel);
            
            MeasureItemHeight(PaintInfo.Canvas, PaintInfo.Node);
            
            PaintInfo.BrushOrigin := Point(Window.Left and 1, BaseOffset and 1);
            Inc(BaseOffset, PaintInfo.Node.NodeHeight);

            TargetRect.Bottom := TargetRect.Top + PaintInfo.Node.NodeHeight;
            
            if (SelectLevel > 0) or not (poSelectedOnly in PaintOptions) then
            begin
              if not (poUnbuffered in PaintOptions) then
              begin
                
                with NodeBitmap do
                begin
                  if Height <> PaintInfo.Node.NodeHeight then
                  begin
                    
                    Height := 0;
                    Height := PaintInfo.Node.NodeHeight;
                    SetCanvasOrigin(Canvas, Window.Left, 0);
                  end;
                end;
              end
              else
              begin
                SetCanvasOrigin(PaintInfo.Canvas, -TargetRect.Left + Window.Left, -TargetRect.Top);
                ClipCanvas(PaintInfo.Canvas, Rect(TargetRect.Left, TargetRect.Top, TargetRect.Right,
                                                  Min(TargetRect.Bottom, MaximumBottom)))
              end;
              
              with PaintInfo do
                SetBrushOrigin(Canvas, BrushOrigin.X, BrushOrigin.Y);

              CurrentNodeHeight := PaintInfo.Node.NodeHeight;
              R.Bottom := CurrentNodeHeight;
              
              CalculateVerticalAlignments(ShowImages, ShowStateImages, PaintInfo.Node, VAlign, ButtonY);
              
              if not DoBeforeItemPaint(PaintInfo.Canvas, PaintInfo.Node, R) then
              begin
                
                PaintInfo.PaintOptions := PaintOptions;
                
                ClearNodeBackground(PaintInfo, UseBackground, True, Rect(Window.Left, TargetRect.Top, Window.Right,
                  TargetRect.Bottom));
                
                PaintInfo.CellRect := R;
                if UseColumns then
                  InitializeFirstColumnValues(PaintInfo);
                
                with FHeader.FColumns do
                begin
                  while ((PaintInfo.Column > InvalidColumn) or not UseColumns)
                    and (PaintInfo.CellRect.Left < Window.Right) do
                  begin
                    if UseColumns then
                    begin
                      PaintInfo.Column := FPositionToIndex[PaintInfo.Position];
                      if FirstColumn = InvalidColumn then
                        FirstColumn := PaintInfo.Column;
                      PaintInfo.BidiMode := Items[PaintInfo.Column].FBiDiMode;
                      PaintInfo.Alignment := Items[PaintInfo.Column].FAlignment;
                    end
                    else
                    begin
                      PaintInfo.Column := NoColumn;
                      PaintInfo.BidiMode := BidiMode;
                      PaintInfo.Alignment := FAlignment;
                    end;

                    PaintInfo.PaintOptions := PaintOptions;
                    with PaintInfo do
                    begin
                      if (tsEditing in FStates) and (Node = FFocusedNode) and
                        ((Column = FEditColumn) or not UseColumns) then
                        Exclude(PaintOptions, poDrawSelection);
                      if not UseColumns or
                        ((vsSelected in Node.States) and (toFullRowSelect in FOptions.FSelectionOptions) and
                         (poDrawSelection in PaintOptions)) or
                        (coParentColor in Items[PaintInfo.Column].Options) then
                        Exclude(PaintOptions, poColumnColor);
                    end;
                    IsMainColumn := PaintInfo.Column = FHeader.MainColumn;
                    
                    if PaintInfo.BidiMode <> bdLeftToRight then
                      ChangeBiDiModeAlignment(PaintInfo.Alignment);
                    
                    if (not UseColumns or (coVisible in Items[PaintInfo.Column].FOptions)) and
                      (not (poMainOnly in PaintOptions) or IsMainColumn) then
                    begin
                      AdjustPaintCellRect(PaintInfo, NextColumn);
                      
                      if PaintInfo.CellRect.Right > Window.Left then
                      begin
                        with PaintInfo do
                        begin
                          
                          NodeWidth := DoGetNodeWidth(Node, Column, Canvas);
                          
                          ContentRect := CellRect;
                          
                          if BidiMode <> bdLeftToRight then
                            Dec(ContentRect.Right, FMargin)
                          else
                            Inc(ContentRect.Left, FMargin);

                          if ShowCheckImages and IsMainColumn then
                          begin
                            ImageInfo[iiCheck].Index := GetCheckImage(Node);
                            if ImageInfo[iiCheck].Index > -1 then
                            begin
                              AdjustImageBorder(FCheckImages, BidiMode, VAlign, ContentRect, ImageInfo[iiCheck]);
                              ImageInfo[iiCheck].Ghosted := False;
                            end;
                          end
                          else
                            ImageInfo[iiCheck].Index := -1;
                          if ShowStateImages then
                          begin
                            GetImageIndex(PaintInfo, ikState, iiState, FStateImages);
                            if ImageInfo[iiState].Index > -1 then
                              AdjustImageBorder(FStateImages, BidiMode, VAlign, ContentRect, ImageInfo[iiState]);
                          end
                          else
                            ImageInfo[iiState].Index := -1;
                          if ShowImages then
                          begin
                            GetImageIndex(PaintInfo, ImageKind[vsSelected in Node.States], iiNormal, FImages);
                            if ImageInfo[iiNormal].Index > -1 then
                              AdjustImageBorder(ImageInfo[iiNormal].Images, BidiMode, VAlign, ContentRect, ImageInfo[iiNormal]);
                          end
                          else
                            ImageInfo[iiNormal].Index := -1;
                          
                          if IsMainColumn then
                            AdjustCoordinatesByIndent(PaintInfo, IfThen(toFixedIndent in FOptions.FPaintOptions, 1, IndentSize));

                          if UseColumns then
                          begin
                            ClipRect := CellRect;
                            if poUnbuffered in PaintOptions then
                            begin
                              ClipRect.Left := Max(ClipRect.Left, Window.Left);
                              ClipRect.Right := Min(ClipRect.Right, Window.Right);
                              ClipRect.Top := Max(ClipRect.Top, Window.Top - (BaseOffset - CurrentNodeHeight));
                              ClipRect.Bottom := ClipRect.Bottom - Max(TargetRect.Bottom - MaximumBottom, 0);
                            end;
                            ClipCanvas(Canvas, ClipRect);
                          end;
                          
                          if (poGridLines in PaintOptions) and (toShowHorzGridLines in FOptions.FPaintOptions) then
                          begin
                            Canvas.Font.Color := FColors.GridLineColor;
                            if IsMainColumn and (FLineMode = lmBands) then
                            begin
                              if BidiMode = bdLeftToRight then
                              begin
                                DrawDottedHLine(PaintInfo, CellRect.Left + IfThen(toFixedIndent in FOptions.FPaintOptions, 1, IndentSize) * Integer(FIndent), CellRect.Right - 1,
                                  CellRect.Bottom - 1);
                              end
                              else
                              begin
                                DrawDottedHLine(PaintInfo, CellRect.Left, CellRect.Right - IfThen(toFixedIndent in FOptions.FPaintOptions, 1, IndentSize) * Integer(FIndent) - 1,
                                  CellRect.Bottom - 1);
                              end;
                            end
                            else
                              DrawDottedHLine(PaintInfo, CellRect.Left, CellRect.Right, CellRect.Bottom - 1);
                            Dec(CellRect.Bottom);
                            Dec(ContentRect.Bottom);
                          end;

                          if UseColumns then
                          begin
                            
                            if (poGridLines in PaintOptions) and (toShowVertGridLines in FOptions.FPaintOptions) and
                              (not (hoAutoResize in FHeader.FOptions) or (Position < TColumnPosition(Count - 1))) then
                            begin
                              if (BidiMode = bdLeftToRight) or not ColumnIsEmpty(Node, Column) then
                              begin
                                Canvas.Font.Color := FColors.GridLineColor;
                                DrawDottedVLine(PaintInfo, CellRect.Top, CellRect.Bottom, CellRect.Right - 1);
                              end;
                              Dec(CellRect.Right);
                              Dec(ContentRect.Right);
                            end;
                          end;
                          
                          PrepareCell(PaintInfo, Window.Left, PaintWidth);
                          
                          if IsMainColumn then
                          begin
                            if (toShowTreeLines in FOptions.FPaintOptions) and
                               (not (toHideTreeLinesIfThemed in FOptions.FPaintOptions) or
                                not (tsUseThemes in FStates)) then
                              PaintTreeLines(PaintInfo, VAlign, IfThen(toFixedIndent in FOptions.FPaintOptions, 1,
                                             IndentSize), LineImage);
                            
                            if (toShowButtons in FOptions.FPaintOptions) and (vsHasChildren in Node.States) and
                              not ((vsAllChildrenHidden in Node.States) and
                              (toAutoHideButtons in TreeOptions.FAutoOptions)) then
                              PaintNodeButton(Canvas, Node, Column, CellRect, ButtonX, ButtonY, BidiMode);

                            if ImageInfo[iiCheck].Index > -1 then
                              PaintCheckImage(Canvas, PaintInfo.ImageInfo[iiCheck], vsSelected in PaintInfo.Node.States);
                          end;

                          if ImageInfo[iiState].Index > -1 then
                            PaintImage(PaintInfo, iiState, False);
                          if ImageInfo[iiNormal].Index > -1 then
                            PaintImage(PaintInfo, iiNormal, True);
                          
                          if not ((tsEditing in FStates) and (Node = FFocusedNode) and
                            ((Column = FEditColumn) or not UseColumns)) then
                            DoPaintNode(PaintInfo);

                          DoAfterCellPaint(Canvas, Node, Column, CellRect);
                        end;
                      end;
                      
                      if not UseColumns then
                        Break;
                    end
                    else
                      NextColumn := GetNextVisibleColumn(PaintInfo.Column);

                    SelectClipRgn(PaintInfo.Canvas.Handle, 0);
                    
                    if (PaintInfo.CellRect.Left >= Window.Right) or (NextColumn = InvalidColumn) then
                      Break;
                    
                    PaintInfo.Position := Items[NextColumn].Position;
                    
                    if coVisible in Items[NextColumn].FOptions then
                      with PaintInfo do
                      begin
                        Items[NextColumn].GetAbsoluteBounds(CellRect.Left, CellRect.Right);
                        CellRect.Bottom := Node.NodeHeight;
                        ContentRect.Bottom := Node.NodeHeight;
                      end;
                  end;
                end;
                
                with PaintInfo do
                begin
                  DoAfterItemPaint(Canvas, Node, R);
                  
                  if (Node = FDropTargetNode) and (toShowDropmark in FOptions.FPaintOptions) and
                    (poDrawDropMark in PaintOptions) then
                    DoPaintDropMark(Canvas, Node, R);
                end;
              end;

              with PaintInfo.Canvas do
              begin
                if DrawSelectionRect then
                begin
                  PaintSelectionRectangle(PaintInfo.Canvas, Window.Left, SelectionRect, Rect(0, 0, PaintWidth,
                    CurrentNodeHeight));
                end;
                
                if not (poUnbuffered in PaintOptions) then
                  with TWithSafeRect(TargetRect), NodeBitmap do
                    BitBlt(TargetCanvas.Handle, Left, Top, Width, Height, Canvas.Handle, Window.Left, 0, SRCCOPY);
              end;
            end;

            Inc(TargetRect.Top, PaintInfo.Node.NodeHeight);
            if TargetRect.Top >= MaximumBottom then
              Break;
            
            if DrawSelectionRect then
              OffsetRect(SelectionRect, 0, -PaintInfo.Node.NodeHeight);
            
            PaintInfo.Node := GetNextVisible(PaintInfo.Node, True);
          end;
        end;
        
        if TargetRect.Top < MaximumBottom then
        begin
          
          BaseOffset := Target.X;
          Target := TargetRect.TopLeft;
          R := Rect(TargetRect.Left, 0, TargetRect.Left, MaximumBottom - Target.Y);
          TargetRect := Rect(0, 0, MaximumRight - Target.X, MaximumBottom - Target.Y);

          if not (poUnbuffered in PaintOptions) then
          begin
            
            NodeBitmap.Height := 0;
            NodeBitmap.PixelFormat := pf32Bit;
            NodeBitmap.Width := TargetRect.Right - TargetRect.Left;
            NodeBitmap.Height := TargetRect.Bottom - TargetRect.Top;
          end;
          
          if not DoPaintBackground(PaintInfo.Canvas, TargetRect) then
          begin
            if UseBackground then
            begin
              SetCanvasOrigin(PaintInfo.Canvas, 0, 0);
              if toStaticBackground in TreeOptions.PaintOptions then
                StaticBackground(FBackground.Bitmap, PaintInfo.Canvas, Target, TargetRect)
              else
                TileBackground(FBackground.Bitmap, PaintInfo.Canvas, Target, TargetRect);
            end
            else
            begin
              
              SetCanvasOrigin(PaintInfo.Canvas, Target.X, 0); 
              if UseColumns then
              begin
                with FHeader.FColumns do
                begin
                  
                  if FirstColumn = InvalidColumn then
                  begin
                    FirstColumn := GetFirstVisibleColumn;
                    repeat
                      if FirstColumn <> InvalidColumn then
                      begin
                        R.Left := Items[FirstColumn].Left;
                        R.Right := R.Left +  Items[FirstColumn].FWidth;
                        if R.Right > TargetRect.Left then
                          Break;
                        FirstColumn := GetNextVisibleColumn(FirstColumn);
                      end;
                    until FirstColumn = InvalidColumn;
                  end
                  else
                  begin
                    R.Left := Items[FirstColumn].Left;
                    R.Right := R.Left +  Items[FirstColumn].FWidth;
                  end;
                  
                  MaxRight := Target.X - 1;

                  PaintInfo.Canvas.Font.Color := FColors.GridLineColor;
                  while (FirstColumn <> InvalidColumn) and (MaxRight < TargetRect.Right + Target.X) do
                  begin
                    
                    ColLeft := Items[FirstColumn].Left;
                    ColRight := (ColLeft + Items[FirstColumn].FWidth);
                    
                    if (ColRight >= MaxRight) then
                    begin
                      R.Left := MaxRight;     
                      R.Right := ColRight;    
                      MaxRight := ColRight;   

                      if (poGridLines in PaintOptions) and
                         (toFullVertGridLines in FOptions.FPaintOptions) and
                         (toShowVertGridLines in FOptions.FPaintOptions) and
                         (not (hoAutoResize in FHeader.FOptions) or (Cardinal(FirstColumn) < TColumnPosition(Count - 1))) then
                      begin
                        DrawDottedVLine(PaintInfo, R.Top, R.Bottom, R.Right - 1);
                        Dec(R.Right);
                      end;

                      if not (coParentColor in Items[FirstColumn].FOptions) then
                        PaintInfo.Canvas.Brush.Color := Items[FirstColumn].FColor
                      else
                        PaintInfo.Canvas.Brush.Color := FColors.BackGroundColor;
                      PaintInfo.Canvas.FillRect(R);
                    end;
                    FirstColumn := GetNextVisibleColumn(FirstColumn);
                  end;
                  
                  if R.Right < TargetRect.Right + Target.X then
                  begin
                    R.Left := R.Right;
                    R.Right := TargetRect.Right + Target.X;
                    
                    if (poGridLines in PaintOptions) and
                       (toFullVertGridLines in FOptions.FPaintOptions) and (toShowVertGridLines in FOptions.FPaintOptions) and
                       (not (hoAutoResize in FHeader.FOptions)) then
                      Inc(R.Left);
                    PaintInfo.Canvas.Brush.Color := FColors.BackGroundColor;
                    PaintInfo.Canvas.FillRect(R);
                  end;
                end;
                SetCanvasOrigin(PaintInfo.Canvas, 0, 0);
              end
              else
              begin
                
                SetCanvasOrigin(PaintInfo.Canvas, 0, 0);
                PaintInfo.Canvas.Brush.Color := FColors.BackGroundColor;
                PaintInfo.Canvas.FillRect(TargetRect);
              end;
            end;
          end;
          SetCanvasOrigin(PaintInfo.Canvas, 0, 0);

          if DrawSelectionRect then
          begin
            R := OrderRect(FNewSelRect);
            
            OffsetRect(R, -Target.X + BaseOffset - Window.Left, -Target.Y + FOffsetY);
            SetBrushOrigin(PaintInfo.Canvas, 0, Target.X and 1);
            PaintSelectionRectangle(PaintInfo.Canvas, 0, R, TargetRect);
          end;

          if not (poUnBuffered in PaintOptions) then
            with Target, NodeBitmap do
              BitBlt(TargetCanvas.Handle, X, Y, Width, Height, Canvas.Handle, 0, 0, SRCCOPY);
        end;
      finally
        PaintInfo.Canvas.Unlock;
        if poUnbuffered in PaintOptions then
          RestoreDC(TargetCanvas.Handle, SavedTargetDC)
        else
          NodeBitmap.Free;
      end;
      
      if (ChildCount[nil] = 0) and (FEmptyListMessage <> '') then
      begin
        
        Canvas.Font := Self.Font;
        SetBkMode(TargetCanvas.Handle, TRANSPARENT);
        R.Left := OffSetX + 2;
        R.Top := 2;
        R.Right := R.Left + Width - 2;
        R.Bottom := Height -2;
        TargetCanvas.Font.Color := clGrayText;
        {$if CompilerVersion >= 20}
        TargetCanvas.TextRect(R, FEmptyListMessage, [tfNoClip, tfLeft, tfWordBreak]);
        {$else}
        TextOutW(TargetCanvas.Handle, 2 - Window.Left, 2 - Window.Top, PWideChar(FEmptyListMessage), Length(FEmptyListMessage));
        {$ifend}
      end;

      DoAfterPaint(TargetCanvas);
    finally
      DoStateChange([], [tsPainting]);
    end;
  end;
end;

function TBaseVirtualTree.PasteFromClipboard: Boolean;

var
  Data: IDataObject;
  Source: TBaseVirtualTree;

begin
  Result := False;
  if not (toReadOnly in FOptions.FMiscOptions) then
  begin
    if OleGetClipboard(Data) <> S_OK then
      ShowError(SClipboardFailed, hcTFClipboardFailed)
    else begin
      
      Source := GetTreeFromDataObject(Data);
      Result := ProcessOLEData(Source, Data, FFocusedNode, FDefaultPasteMode, Assigned(Source) and
        (tsCutPending in Source.FStates));
      if Assigned(Source) then begin
        if Source <> Self then
          Source.FinishCutOrCopy
        else
          DoStateChange([], [tsCutPending]);
      end;    
    end;
  end;
end;

procedure TBaseVirtualTree.PrepareDragImage(Hotspot: TPoint; const DataObject: IDataObject);

var
  PaintOptions: TVTInternalPaintOptions;
  TreeRect,
  PaintRect: TRect;
  LocalSpot,
  ImagePos,
  PaintTarget: TPoint;
  Image: TBitmap;

begin
  if CanShowDragImage then
  begin
    
    LocalSpot := HotSpot;
    Dec(LocalSpot.X, -FEffectiveOffsetX);
    Dec(LocalSpot.Y, FOffsetY);
    TreeRect := Rect(LocalSpot.X - FDragWidth div 2, LocalSpot.Y - FDragHeight div 2, LocalSpot.X + FDragWidth div 2,
      LocalSpot.Y + FDragHeight div 2);
    
    PaintRect := TreeRect;
    with TWithSafeRect(TreeRect) do
    begin
      if Left < 0 then
      begin
        PaintTarget.X := -Left;
        PaintRect.Left := 0;
      end
      else
        PaintTarget.X := 0;
      if Top < 0 then
      begin
        PaintTarget.Y := -Top;
        PaintRect.Top := 0;
      end
      else
        PaintTarget.Y := 0;
    end;

    Image := TBitmap.Create;
    with Image do
    try
      PixelFormat := pf32Bit;
      Width := TreeRect.Right - TreeRect.Left;
      Height := TreeRect.Bottom - TreeRect.Top;
      
      Canvas.Brush.Color := FColors.BackGroundColor;
      Canvas.FillRect(Rect(0, 0, Width, Height));

      PaintOptions := [poDrawSelection, poSelectedOnly];
      if FDragImageKind = diMainColumnOnly then
        Include(PaintOptions, poMainOnly);
      PaintTree(Image.Canvas, PaintRect, PaintTarget, PaintOptions);
      
      OffsetRect(TreeRect, -FEffectiveOffsetX, FOffsetY);
      ImagePos := ClientToScreen(TreeRect.TopLeft);
      HotSpot := ClientToScreen(HotSpot);

      FDragImage.ColorKey := FColors.BackGroundColor;
      FDragImage.PrepareDrag(Image, ImagePos, HotSpot, DataObject);
    finally
      Image.Free;
    end;
  end;
end;

procedure TBaseVirtualTree.Print(Printer: TPrinter; PrintHeader: Boolean);

var
  SaveTreeFont: TFont;                 
  SaveHeaderFont: TFont;               
  ImgRect,                             
  TreeRect,                            
  DestRect,                            
  SrcRect: TRect;                      
  P: TPoint;                           
  Options: TVTInternalPaintOptions;    
  Image,                               
  PrinterImage: TBitmap;               
  SaveColor: TColor;                   
  pTxtHeight,                          
  vTxtHeight,                          
  vPageWidth,
  vPageHeight,                         
  xPageNum, yPageNum,                  
  xPage, yPage: Integer;               
  Scale: Extended;                     
  LogFont: TLogFont;

begin
  if Assigned(Printer) then
  begin
    BeginUpdate;
    
    Options := [poGridLines];
    
    SaveTreeFont := TFont.Create;
    SaveTreeFont.Assign(Font);
    
    GetObject(Font.Handle, SizeOf(TLogFont), @LogFont);
    LogFont.lfQuality := ANTIALIASED_QUALITY;
    Font.Handle := CreateFontIndirect(LogFont);
    
    Image := TBitmap.Create;
    Image.PixelFormat := pf32Bit;
    PrinterImage := nil;
    try
      TreeRect := GetTreeRect;

      Image.Width := TreeRect.Right - TreeRect.Left;
      P := Point(0, 0);
      if (hoVisible in FHeader.Options) and PrintHeader then
      begin
        Inc(TreeRect.Bottom, FHeader.Height);
        Inc(P.Y, FHeader.Height);
      end;
      Image.Height := TreeRect.Bottom - TreeRect.Top;

      ImgRect.Left := 0;
      ImgRect.Top := 0;
      ImgRect.Right := Image.Width;
      
      SaveColor := FColors.BackGroundColor;
      Color :=clWhite;

      if (hoVisible in FHeader.Options) and PrintHeader then
      begin
        SaveHeaderFont := TFont.Create;
        try
          SaveHeaderFont.Assign(FHeader.Font);
          
          GetObject(FHeader.Font.Handle, SizeOf(TLogFont), @LogFont);
          LogFont.lfQuality := ANTIALIASED_QUALITY;
          FHeader.Font.Handle := CreateFontIndirect(LogFont);
          ImgRect.Bottom := FHeader.Height;
          FHeader.FColumns.PaintHeader(Image.Canvas.Handle, ImgRect, 0);
          FHeader.Font := SaveHeaderFont;
        finally
          SaveHeaderFont.Free;
        end;
      end;
      
      ImgRect.Bottom := Image.Height;

      PaintTree(Image.Canvas, ImgRect, P, Options, pf32Bit);
      Color := SaveColor;
      
      Printer.BeginDoc;
      Printer.Canvas.Font := Font;
      
      pTxtHeight := Printer.Canvas.TextHeight('Tj');
      vTxtHeight := Canvas.TextHeight('Tj');

      Scale := pTxtHeight / vTxtHeight;
      
      PrinterImage := TBitmap.Create;

      vPageHeight := Round(Printer.PageHeight / Scale);
      vPageWidth := Round(Printer.PageWidth / Scale);
      
      xPageNum := Trunc(Image.Width / vPageWidth);
      yPageNum := Trunc(Image.Height / vPageHeight);

      PrinterImage.Width := vPageWidth;
      PrinterImage.Height := vPageHeight;
      
      for yPage := 0 to yPageNum do
      begin
        DestRect.Left := 0;
        DestRect.Top := 0;
        DestRect.Right := PrinterImage.Width;
        DestRect.Bottom := PrinterImage.Height;
        
        for xPage := 0 to xPageNum do
          begin
            SrcRect.Left := vPageWidth * xPage;
            SrcRect.Top := vPageHeight * yPage;
            SrcRect.Right := vPageWidth * xPage + PrinterImage.Width;
            SrcRect.Bottom := SrcRect.Top + vPageHeight;
            
            PrinterImage.Canvas.Brush.Color := clWhite;
            PrinterImage.Canvas.FillRect(Rect(0, 0, PrinterImage.Width, PrinterImage.Height));
            PrinterImage.Canvas.CopyRect(DestRect, Image.Canvas, SrcRect);
            PrtStretchDrawDIB(Printer.Canvas, Rect(0, 0, Printer.PageWidth, Printer.PageHeight - 1), PrinterImage);
            if xPage <> xPageNum then
              Printer.NewPage;
          end;
        if yPage <> yPageNum then
          Printer.NewPage;
      end;
      
      Font := SaveTreeFont;
      SaveTreeFont.Free;
      Printer.EndDoc;
    finally
      PrinterImage.Free;
      Image.Free;
      EndUpdate;
    end;
  end;
end;

function TBaseVirtualTree.ProcessDrop(DataObject: IDataObject; TargetNode: PVirtualNode; var Effect: Integer;
  Mode: TVTNodeAttachMode): Boolean;

var
  Source: TBaseVirtualTree;

begin
  Result := False;
  if Mode = amNoWhere then
    Effect := DROPEFFECT_NONE
  else
  begin
    BeginUpdate;
    
    Source := GetTreeFromDataObject(DataObject);
    if Assigned(Source) then
      Source.BeginUpdate;
    try
      try
        
        if ((Effect and DROPEFFECT_MOVE) <> 0) and Assigned(Source) then
        begin
          
          Result := ProcessOLEData(Source, DataObject, TargetNode, Mode, (Effect and DROPEFFECT_COPY) = 0);
          
          Effect := DROPEFFECT_NONE;
        end
        else
          
          if (Effect and (DROPEFFECT_MOVE or DROPEFFECT_COPY)) <> 0 then
            Result := ProcessOLEData(Source, DataObject, TargetNode, Mode, False)
          else
            Result := False;
      except
        Effect := DROPEFFECT_NONE;
      end;
    finally
      if Assigned(Source) then
        Source.EndUpdate;
      EndUpdate;
    end;
  end;
end;

type
  
  TOLEMemoryStream = class(TCustomMemoryStream)
  public
    function Write(const Buffer; Count: Integer): Longint; override;
  end;

function TOLEMemoryStream.Write(const Buffer; Count: Integer): Integer;

begin
  raise EStreamError.CreateRes(PResStringRec(@SCantWriteResourceStreamError));
end;

procedure TBaseVirtualTree.DoDrawHint(Canvas: TCanvas; Node: PVirtualNode; R:
    TRect; Column: TColumnIndex);

begin
  if Assigned(FOnDrawHint) then
    FOnDrawHint(Self, Canvas, Node, R, Column);
end;

procedure TBaseVirtualTree.DoGetHintSize(Node: PVirtualNode; Column:
    TColumnIndex; var R: TRect);

begin
  if Assigned(FOnGetHintSize) then
    FOnGetHintSize(Self, Node, Column, R);
end;

procedure TBaseVirtualTree.DoGetHintKind(Node: PVirtualNode; Column:
    TColumnIndex; var Kind: TVTHintKind);

begin
  if Assigned(fOnGetHintKind) then
    fOnGetHintKind(Self, Node, Column, Kind)
  else
    Kind := DefaultHintKind;
end;

function TBaseVirtualTree.GetDefaultHintKind: TVTHintKind;

begin
  Result := vhkText;
end;

function TBaseVirtualTree.ProcessOLEData(Source: TBaseVirtualTree; DataObject: IDataObject; TargetNode: PVirtualNode;
  Mode: TVTNodeAttachMode; Optimized: Boolean): Boolean;

var
  Medium: TStgMedium;
  Stream: TStream;
  Data: Pointer;
  Node: PVirtualNode;
  Nodes: TNodeArray;
  I: Integer;
  Res: HRESULT;
  ChangeReason: TChangeReason;

begin
  Nodes := nil;
  
  with StandardOLEFormat do
  begin
    
    cfFormat := CF_VIRTUALTREE;
  end;
  Result := DataObject.QueryGetData(StandardOLEFormat) = S_OK;
  if Result and not (toReadOnly in FOptions.FMiscOptions) then
  begin
    BeginUpdate;
    Result := False;
    try
      if TargetNode = nil then
        TargetNode := FRoot;
      if TargetNode = FRoot then
      begin
        case Mode of
          amInsertBefore:
            Mode := amAddChildFirst;
          amInsertAfter:
            Mode := amAddChildLast;
        end;
      end;
      
      if Optimized then
      begin
        if tsOLEDragging in Source.FStates then
          Nodes := Source.FDragSelection
        else
          Nodes := Source.GetSortedCutCopySet(True);

        if Mode in [amInsertBefore,amAddChildLast] then
        begin
          for I := 0 to High(Nodes) do
            if not HasAsParent(TargetNode, Nodes[I]) then
              Source.MoveTo(Nodes[I], TargetNode, Mode, False);
        end
        else
        begin
          for I := High(Nodes) downto 0 do
            if not HasAsParent(TargetNode, Nodes[I]) then
              Source.MoveTo(Nodes[I], TargetNode, Mode, False);
        end;
        Result := True;
      end
      else
      begin
        if Source = Self then
          ChangeReason := crNodeCopied
        else
          ChangeReason := crNodeAdded;
        Res := DataObject.GetData(StandardOLEFormat, Medium);
        if Res = S_OK then
        begin
          case Medium.tymed of
            TYMED_ISTREAM, 
            TYMED_HGLOBAL: 
              begin
                Stream := nil;
                if Medium.tymed = TYMED_ISTREAM then
                  Stream := TOLEStream.Create(IUnknown(Medium.stm) as IStream)
                else
                begin
                  Data := GlobalLock(Medium.hGlobal);
                  if Assigned(Data) then
                  begin
                    
                    I := PCardinal(Data)^;
                    Inc(PCardinal(Data));
                    Stream := TOLEMemoryStream.Create;
                    TOLEMemoryStream(Stream).SetPointer(Data, I);
                  end;
                end;

                if Assigned(Stream) then
                try
                  while Stream.Position < Stream.Size do
                  begin
                    Node := MakeNewNode;
                    InternalConnectNode(Node, TargetNode, Self, Mode);
                    InternalAddFromStream(Stream, VTTreeStreamVersion, Node);
                    
                    if not DoNodeCopying(Node, TargetNode) then begin
                      DeleteNode(Node)
                    end
                    else begin
                      DoNodeCopied(Node);
                      StructureChange(Node, ChangeReason);
                      
                      if Mode = amInsertAfter then
                        TargetNode := Node;
                    end;
                  end;
                  Result := True;
                finally
                  Stream.Free;
                  if Medium.tymed = TYMED_HGLOBAL then
                    GlobalUnlock(Medium.hGlobal);
                end;
              end;
          end;
          ReleaseStgMedium(Medium);
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TBaseVirtualTree.ReinitChildren(Node: PVirtualNode; Recursive: Boolean);

var
  Run: PVirtualNode;

begin
  if Assigned(Node) then
  begin
    InitChildren(Node);
    Run := Node.FirstChild;
  end
  else
  begin
    InitChildren(FRoot);
    Run := FRoot.FirstChild;
  end;

  while Assigned(Run) do
  begin
    ReinitNode(Run, Recursive);
    Run := Run.NextSibling;
  end;
end;

procedure TBaseVirtualTree.ReinitNode(Node: PVirtualNode; Recursive: Boolean);

begin
  if Assigned(Node) and (Node <> FRoot) then
  begin
    
    Node.States := Node.States - [vsChecking, vsCutOrCopy, vsDeleting, vsHeightMeasured];
    InitNode(Node);
  end;

  if Recursive then
    ReinitChildren(Node, True);
end;

procedure TBaseVirtualTree.RepaintNode(Node: PVirtualNode);

var
  R: Trect;

begin
  if Assigned(Node) and (Node <> FRoot) then
  begin
    R := GetDisplayRect(Node, -1, False);
    RedrawWindow(Handle, @R, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE or RDW_VALIDATE or RDW_NOCHILDREN);
  end;
end;

procedure TBaseVirtualTree.ResetNode(Node: PVirtualNode);

begin
  DoCancelEdit;
  if (Node = nil) or (Node = FRoot) then
    Clear
  else
  begin
    DoReset(Node);
    DeleteChildren(Node);
    
    Node.States := Node.States - [vsInitialized, vsChecking, vsCutOrCopy, vsDeleting, vsHasChildren, vsExpanded,
      vsHeightMeasured];
    InvalidateNode(Node);
  end;
end;

procedure TBaseVirtualTree.SaveToFile(const FileName: TFileName);

var
  FileStream: TFileStream;

begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TBaseVirtualTree.SaveToStream(Stream: TStream; Node: PVirtualNode = nil);

var
  Count: Cardinal;

begin
  Stream.Write(MagicID, SizeOf(MagicID));
  if Node = nil then
  begin
    
    Count := FRoot.ChildCount;
    Stream.WriteBuffer(Count, SizeOf(Count));
    
    Node := FRoot.FirstChild;
    while Assigned(Node) do
    begin
      WriteNode(Stream, Node);
      Node := Node.NextSibling;
    end;
  end
  else
  begin
    Count := 1;
    Stream.WriteBuffer(Count, SizeOf(Count));
    WriteNode(Stream, Node);
  end;
  if Assigned(FOnSaveTree) then
    FOnSaveTree(Self, Stream);
end;

function TBaseVirtualTree.ScrollIntoView(Node: PVirtualNode; Center: Boolean; Horizontally: Boolean = False): Boolean;

var
  R: TRect;
  Run: PVirtualNode;
  UseColumns,
  HScrollBarVisible: Boolean;
  ScrolledVertically,
  ScrolledHorizontally: Boolean;

begin
  ScrolledVertically   := False;
  ScrolledHorizontally := False;

  if Assigned(Node) and (Node <> FRoot) then
  begin
    
    Run := Node.Parent;
    while Run <> FRoot do
    begin
      if not (vsExpanded in Run.States) then
        ToggleNode(Run);
      Run := Run.Parent;
    end;
    UseColumns := FHeader.UseColumns;
    if UseColumns and FHeader.FColumns.IsValidColumn(FFocusedColumn) then
      R := GetDisplayRect(Node, FFocusedColumn, not (toGridExtensions in FOptions.FMiscOptions))
    else
      R := GetDisplayRect(Node, NoColumn, not (toGridExtensions in FOptions.FMiscOptions));
    
    if R.Top < 0 then
    begin
      if Center then
        SetOffsetY(FOffsetY - R.Top + ClientHeight div 2)
      else
        SetOffsetY(FOffsetY - R.Top);
      ScrolledVertically := True;
    end
    else
      if (R.Bottom > ClientHeight) or Center then
      begin
        HScrollBarVisible := (ScrollBarOptions.ScrollBars in [{$if CompilerVersion >=24}System.UITypes.TScrollStyle.{$ifend}ssBoth, {$if CompilerVersion >=24}System.UITypes.TScrollStyle.{$ifend}ssHorizontal]) and
          (ScrollBarOptions.AlwaysVisible or (Integer(FRangeX) > ClientWidth));
        if Center then
          SetOffsetY(FOffsetY - R.Bottom + ClientHeight div 2)
        else
          SetOffsetY(FOffsetY - R.Bottom + ClientHeight);
        
        if not UseColumns and not HScrollBarVisible and (Integer(FRangeX) > ClientWidth) then
          SetOffsetY(FOffsetY - GetSystemMetrics(SM_CYHSCROLL));
        ScrolledVertically := True;
      end;

    if Horizontally then
      
      ScrolledHorizontally := ScrollIntoView(FFocusedColumn, Center);

  end;

  Result := ScrolledVertically or ScrolledHorizontally;
end;

function TBaseVirtualTree.ScrollIntoView(Column: TColumnIndex; Center: Boolean): Boolean;

var
  ColumnLeft,
  ColumnRight: Integer;
  NewOffset: Integer;

begin
  Result := False;

  if not FHeader.UseColumns then exit;
  if not FHeader.Columns.IsValidColumn(Column) then exit; 

  ColumnLeft := Header.Columns.Items[Column].Left;
  ColumnRight := ColumnLeft + Header.Columns.Items[Column].Width;

  NewOffset := FEffectiveOffsetX;
  if Center then
  begin
    NewOffset := FEffectiveOffsetX + ColumnLeft - (Header.Columns.GetVisibleFixedWidth div 2) - (ClientWidth div 2) + ((ColumnRight - ColumnLeft) div 2);
    if NewOffset <> FEffectiveOffsetX then
    begin
      if UseRightToLeftAlignment then
        SetOffsetX(-Integer(FRangeX) + ClientWidth + NewOffset)
      else
        SetOffsetX(-NewOffset);
    end;
    Result := True;
  end
  else
  begin
    if ColumnRight > ClientWidth then
      NewOffset := FEffectiveOffsetX + (ColumnRight - ClientWidth)
    else if ColumnLeft < Header.Columns.GetVisibleFixedWidth then
      NewOffset := FEffectiveOffsetX - (Header.Columns.GetVisibleFixedWidth - ColumnLeft);
    if NewOffset <> FEffectiveOffsetX then
    begin
      if UseRightToLeftAlignment then
        SetOffsetX(-Integer(FRangeX) + ClientWidth + NewOffset)
      else
        SetOffsetX(-NewOffset);
    end;
    Result := True;
  end;
end;

procedure TBaseVirtualTree.SelectAll(VisibleOnly: Boolean);

var
  Run: PVirtualNode;
  NextFunction: TGetNextNodeProc;

begin
  if not FSelectionLocked and (toMultiSelect in FOptions.FSelectionOptions) then
  begin
    ClearTempCache;
    if VisibleOnly then
    begin
      Run := GetFirstVisible(nil, True);
      NextFunction := GetNextVisible;
    end
    else
    begin
      Run := GetFirst;
      NextFunction := GetNext;
    end;

    while Assigned(Run) do
    begin
      if not(vsSelected in Run.States) then
        InternalCacheNode(Run);
      Run := NextFunction(Run);
    end;
    if FTempNodeCount > 0 then
      AddToSelection(FTempNodeCache, FTempNodeCount);
    ClearTempCache;
    Invalidate;
  end;
end;

procedure TBaseVirtualTree.Sort(Node: PVirtualNode; Column: TColumnIndex; Direction: TSortDirection; DoInit: Boolean = True);

  function MergeAscending(A, B: PVirtualNode): PVirtualNode;

  var
    Dummy: TVirtualNode;
    CompareResult: Integer;
  begin
    
    Result := @Dummy;
    while Assigned(A) and Assigned(B) do
    begin
      if OperationCanceled then
        CompareResult := 0
      else
        CompareResult := DoCompare(A, B, Column);

      if CompareResult <= 0 then
      begin
        Result.NextSibling := A;
        Result := A;
        A := A.NextSibling;
      end
      else
      begin
        Result.NextSibling := B;
        Result := B;
        B := B.NextSibling;
      end;
    end;
    
    if Assigned(A) then
      Result.NextSibling := A
    else
      Result.NextSibling := B;
    
    Result := Dummy.NextSibling;
  end;

  function MergeDescending(A, B: PVirtualNode): PVirtualNode;

  var
    Dummy: TVirtualNode;
    CompareResult: Integer;

  begin
    
    Result := @Dummy;
    while Assigned(A) and Assigned(B) do
    begin
      if OperationCanceled then
        CompareResult := 0
      else
        CompareResult := DoCompare(A, B, Column);

      if CompareResult >= 0 then
      begin
        Result.NextSibling := A;
        Result := A;
        A := A.NextSibling;
      end
      else
      begin
        Result.NextSibling := B;
        Result := B;
        B := B.NextSibling;
      end;
    end;
    
    if Assigned(A) then
      Result.NextSibling := A
    else
      Result.NextSibling := B;
    
    Result := Dummy.NextSibling;
  end;

  function MergeSortAscending(var Node: PVirtualNode; N: Cardinal): PVirtualNode;

  var
    A, B: PVirtualNode;

  begin
    if N > 1 then
    begin
      A := MergeSortAscending(Node, N div 2);
      B := MergeSortAscending(Node, (N + 1) div 2);
      Result := MergeAscending(A, B);
    end
    else
    begin
      Result := Node;
      Node := Node.NextSibling;
      Result.NextSibling := nil;
    end;
  end;

  function MergeSortDescending(var Node: PVirtualNode; N: Cardinal): PVirtualNode;

  var
    A, B: PVirtualNode;

  begin
    if N > 1 then
    begin
      A := MergeSortDescending(Node, N div 2);
      B := MergeSortDescending(Node, (N + 1) div 2);
      Result := MergeDescending(A, B);
    end
    else
    begin
      Result := Node;
      Node := Node.NextSibling;
      Result.NextSibling := nil;
    end;
  end;

var
  Run: PVirtualNode;
  Index: Cardinal;

begin
  InterruptValidation;
  if tsEditPending in FStates then
  begin
    StopTimer(EditTimer);
    DoStateChange([], [tsEditPending]);
  end;

  if not (tsEditing in FStates) or DoEndEdit then
  begin
    if Node = nil then
      Node := FRoot;
    if vsHasChildren in Node.States then
    begin
      if (Node.ChildCount = 0) and DoInit then
        InitChildren(Node);
      
      if DoInit and (Node.ChildCount > 0) then
        ValidateChildren(Node, False);
      
      if Node.ChildCount > 1 then
      begin
        StartOperation(okSortNode);
        try
          
          if Direction = sdAscending then
            Node.FirstChild := MergeSortAscending(Node.FirstChild, Node.ChildCount)
          else
            Node.FirstChild := MergeSortDescending(Node.FirstChild, Node.ChildCount);
        finally
          EndOperation(okSortNode);
        end;
        
        Run := Node.FirstChild;
        Run.PrevSibling := nil;
        Index := 0;
        repeat
          Run.Index := Index;
          Inc(Index);
          if Run.NextSibling = nil then
            Break;
          Run.NextSibling.PrevSibling := Run;
          Run := Run.NextSibling;
        until False;
        Node.LastChild := Run;

        InvalidateCache;
      end;
      if FUpdateCount = 0 then
      begin
        ValidateCache;
        Invalidate;
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.SortTree(Column: TColumnIndex; Direction: TSortDirection; DoInit: Boolean = True);

  procedure DoSort(Node: PVirtualNode);

  var
    Run: PVirtualNode;

  begin
    Sort(Node, Column, Direction, DoInit);
    
    Run := Node.FirstChild;
    while Assigned(Run) and not FOperationCanceled do
    begin
      if DoInit and not (vsInitialized in Run.States) then
        InitNode(Run);
      if (vsInitialized in Run.States) and (not (toAutoSort in TreeOptions.AutoOptions) or Expanded[Run]) then 
        DoSort(Run);
      Run := Run.NextSibling;
    end;
  end;

begin
  if RootNode.TotalCount <= 2 then
    exit;
  
  Inc(FUpdateCount);
  try
    if Column > InvalidColumn then
    begin
      StartOperation(okSortTree);
      try
        DoSort(FRoot);
      finally
        EndOperation(okSortTree);
      end; 
    end;
    InvalidateCache;
  finally
    if FUpdateCount > 0 then
      Dec(FUpdateCount);
    if FUpdateCount = 0 then
    begin
      ValidateCache;
      Invalidate;
    end;
  end;
end;

procedure TBaseVirtualTree.ToggleNode(Node: PVirtualNode);

var
  Child,
  FirstVisible: PVirtualNode;
  HeightDelta,
  StepsR1,
  StepsR2,
  Steps: Integer;
  TogglingTree,
  ChildrenInView,
  NeedFullInvalidate,
  NeedUpdate,
  NodeInView,
  PosHoldable,
  TotalFit: Boolean;
  ToggleData: TToggleAnimationData;

  procedure PrepareAnimation;

  var
    R: TRect;
    S: Integer;
    M: TToggleAnimationMode;

  begin
    with ToggleData do
    begin
      Window := Handle;
      DC := GetDC(Handle);
      Self.Brush.Color := FColors.BackGroundColor;
      Brush := Self.Brush.Handle;

      if (Mode1 <> tamNoScroll) and (Mode2 <> tamNoScroll) then
      begin
        if StepsR1 < StepsR2 then
        begin
          
          R := R2;
          R2 := R1;
          R1 := R;

          M := Mode2;
          Mode2 := Mode1;
          Mode1 := M;

          S := StepsR2;
          StepsR2 := StepsR1;
          StepsR1 := S;
        end;
        ScaleFactor := StepsR2 / StepsR1;
        MissedSteps := 0;
      end;

      if Mode1 <> tamNoScroll then
        Steps := StepsR1
      else
        Steps := StepsR2;
    end;
  end;

begin
  Assert(Assigned(Node), 'Node must not be nil.');

  TogglingTree := tsToggling in FStates;
  ChildrenInView := False;
  HeightDelta := 0;
  NeedFullInvalidate := False;
  NeedUpdate := False;
  NodeInView := False;
  PosHoldable := False;
  TotalFit := False;
  
  if [vsDeleting, vsToggling] * Node.States = [] then
  begin
    try
      DoStateChange([tsToggling]);
      Include(Node.States, vsToggling);

      if vsExpanded in Node.States then
      begin
        if DoCollapsing(Node) then
        begin
          NeedUpdate := True;
          
          HeightDelta := -Integer(Node.TotalHeight) + Integer(NodeHeight[Node]); 
          if (FUpdateCount = 0) and (toAnimatedToggle in FOptions.FAnimationOptions) and not
             (tsCollapsing in FStates) then
          begin
            Application.CancelHint;
            UpdateWindow(Handle);
            
            with ToggleData do
            begin
              
              R1 := GetDisplayRect(Node, NoColumn, False);
              Mode2 := tamNoScroll;
              if toChildrenAbove in FOptions.FPaintOptions then
              begin
                PosHoldable := (FOffsetY + (Integer(Node.TotalHeight) - Integer(NodeHeight[Node]))) <= 0;
                NodeInView := R1.Top < ClientHeight;

                StepsR1 := 0;
                if NodeInView then
                begin
                  if PosHoldable or not (toAdvancedAnimatedToggle in FOptions.FAnimationOptions) then
                  begin
                    
                    Mode1 := tamScrollDown;
                    R1.Bottom := R1.Top;
                    R1.Top := 0;
                    StepsR1 := Min(R1.Bottom - R1.Top + 1, Integer(Node.TotalHeight) - Integer(NodeHeight[Node]));
                  end
                  else
                  begin
                    
                    Mode1 := tamScrollUp;
                    R1.Top := Max(0, R1.Top + HeightDelta);
                    R1.Bottom := ClientHeight;
                    StepsR1 := FOffsetY - HeightDelta;
                  end;
                end;
              end
              else
              begin
                if (Integer(FRangeY) + FOffsetY - R1.Bottom + HeightDelta >= ClientHeight - R1.Bottom) or
                   (Integer(FRangeY) <= ClientHeight) or (FOffsetY = 0) or not
                   (toAdvancedAnimatedToggle in FOptions.FAnimationOptions) then
                begin
                  
                  Mode1 := tamScrollUp;
                  Inc(R1.Top, NodeHeight[Node]);
                  R1.Bottom := ClientHeight;
                  StepsR1 := Min(R1.Bottom - R1.Top + 1, -HeightDelta);
                end
                else
                begin
                  
                  Mode1 := tamScrollDown;
                  StepsR1 := Min(-FOffsetY, ClientHeight - Integer(FRangeY) -FOffsetY - HeightDelta);
                  R1.Top := 0;
                  R1.Bottom := Min(ClientHeight, R1.Bottom + Steps);
                  NeedFullInvalidate := True;
                end;
              end;
              
              if R1.Top < ClientHeight then
              begin
                PrepareAnimation;
                try
                  Animate(Steps, FAnimationDuration, ToggleCallback, @ToggleData);
                finally
                  ReleaseDC(Window, DC);
                end;
              end;
            end;
          end;
          
          AdjustTotalHeight(Node, IfThen(IsEffectivelyFiltered[Node], 0, NodeHeight[Node]));
          if FullyVisible[Node] then
            Dec(FVisibleCount, CountVisibleChildren(Node));
          Exclude(Node.States, vsExpanded);
          DoCollapsed(Node);
          
          if (toAutoFreeOnCollapse in FOptions.FAutoOptions) and (Node.ChildCount > 0) then
          begin
            DeleteChildren(Node);
            Include(Node.States, vsHasChildren);
          end;
        end;
      end
      else
        if DoExpanding(Node) then
        begin
          NeedUpdate := True;
          
          if not (vsInitialized in Node.States) then
            InitNode(Node);
          if (vsHasChildren in Node.States) and (Node.ChildCount = 0) then
            InitChildren(Node);
          
          if Node.ChildCount > 0 then
          begin
            
            Child := Node.FirstChild;
            repeat
              if vsVisible in Child.States then
              begin
                
                MeasureItemHeight(Canvas, Child);

                Inc(HeightDelta, Child.TotalHeight);
              end;
              Child := Child.NextSibling;
            until Child = nil;
            
            if (toChildrenAbove in FOptions.FPaintOptions) or (FUpdateCount = 0) then
            begin
              with ToggleData do
              begin
                R1 := GetDisplayRect(Node, NoColumn, False);
                Mode2 := tamNoScroll;
                TotalFit := HeightDelta + Integer(NodeHeight[Node]) <= ClientHeight;

                if toChildrenAbove in FOptions.FPaintOptions then
                begin
                  
                  PosHoldable := TotalFit and (Integer(FRangeY) - ClientHeight >= 0) ;
                  ChildrenInView := (R1.Top - HeightDelta) >= 0;
                  NodeInView := R1.Bottom <= ClientHeight;
                end
                else
                begin
                  PosHoldable := TotalFit;
                  ChildrenInView := R1.Bottom + HeightDelta <= ClientHeight;
                end;

                R1.Bottom := ClientHeight;
              end;
            end;

            if FUpdateCount = 0 then
            begin
              
              if (ToggleData.R1.Top < ClientHeight) and ([tsPainting, tsExpanding] * FStates = []) and
                (toAnimatedToggle in FOptions.FAnimationOptions)then
              begin
                Application.CancelHint;
                UpdateWindow(Handle);
                
                with ToggleData do
                begin
                  if toChildrenAbove in FOptions.FPaintOptions then
                  begin
                    
                    if not (toAdvancedAnimatedToggle in FOptions.FAnimationOptions) or
                       (PosHoldable and ( (NodeInView and ChildrenInView) or not
                                          (toAutoScrollOnExpand in FOptions.FAutoOptions) )) then
                    begin
                      Mode1 := tamScrollUp;
                      R1 := Rect(R1.Left, 0, R1.Right, R1.Top);
                      StepsR1 := Min(HeightDelta, R1.Bottom);
                    end
                    else
                    begin
                      
                      Mode1 := tamScrollDown;
                      Mode2 := tamScrollUp;
                      R2 := Rect(R1.Left, 0, R1.Right, R1.Top);
                      if not (toAutoScrollOnExpand in FOptions.FAutoOptions) then
                      begin
                        
                        StepsR1 := -FOffsetY - Max(Integer(FRangeY) + HeightDelta - ClientHeight, 0) + HeightDelta;
                        if (Integer(FRangeY) + HeightDelta - ClientHeight) <= 0 then
                          Mode2 := tamNoScroll
                        else
                          StepsR2 := Min(Integer(FRangeY) + HeightDelta - ClientHeight, R2.Bottom);
                      end
                      else
                      begin
                        if TotalFit and NodeInView and (Integer(FRangeY) + HeightDelta > ClientHeight) then
                        begin
                          
                          if HeightDelta >= R1.Top then
                            StepsR1 := Abs(R1.Top - HeightDelta)
                          else
                            StepsR1 := ClientHeight - Integer(FRangeY);
                        end
                        else
                          if Integer(FRangeY) + HeightDelta <= ClientHeight then
                          begin
                            
                            Mode2 := tamNoScroll;
                            StepsR1 := HeightDelta;
                          end
                          else
                            
                            StepsR1 := ClientHeight - R1.Top - Integer(NodeHeight[Node]);

                        if Mode2 <> tamNoScroll then
                        begin
                          if StepsR1 > 0 then
                            StepsR2 := Min(R1.Top, HeightDelta - StepsR1)
                          else
                          begin
                            
                            Mode1 := tamNoScroll;
                            StepsR2 := Min(HeightDelta, R1.Bottom);
                          end;
                        end;
                      end;
                    end;
                  end
                  else
                  begin
                    
                    if (PosHoldable and ChildrenInView) or not (toAutoScrollOnExpand in FOptions.FAutoOptions) or not
                       (toAdvancedAnimatedToggle in FOptions.FAnimationOptions) or (R1.Top <= 0) then
                    begin
                      
                      Mode1 := tamScrollDown;
                      Inc(R1.Top, NodeHeight[Node]);
                      StepsR1 := Min(R1.Bottom - R1.Top, HeightDelta);
                    end
                    else
                    begin
                      
                      Mode1 := tamScrollUp;
                      Mode2 := tamScrollDown;

                      R1.Bottom := R1.Top + Integer(NodeHeight[Node]) + 1;
                      R1.Top := 0;
                      R2 := Rect(R1.Left, R1.Bottom, R1.Right, ClientHeight);

                      StepsR1 := Min(HeightDelta - (ClientHeight - R2.Top), R1.Bottom - Integer(NodeHeight[Node]));
                      StepsR2 := ClientHeight - R2.Top;
                    end;
                  end;

                  if ClientHeight >= R1.Top then
                  begin
                    PrepareAnimation;
                    try
                      Animate(Steps, FAnimationDuration, ToggleCallback, @ToggleData);
                    finally
                      ReleaseDC(Window, DC);
                    end;
                  end;
                end;
              end;
              if toAutoSort in FOptions.FAutoOptions then
                Sort(Node, FHeader.FSortColumn, FHeader.FSortDirection, False);
            end;

            Include(Node.States, vsExpanded);
            AdjustTotalHeight(Node, HeightDelta, True);
            if FullyVisible[Node] then
              Inc(FVisibleCount, CountVisibleChildren(Node));

            DoExpanded(Node);
          end;
        end;

      if NeedUpdate then
      begin
        InvalidateCache;
        if FUpdateCount = 0 then
        begin
          ValidateCache;
          if Node.ChildCount > 0 then
          begin
            UpdateRanges;
            UpdateScrollbars(True);
            if [tsPainting, tsExpanding] * FStates = [] then
            begin
              if (vsExpanded in Node.States) and ((toAutoScrollOnExpand in FOptions.FAutoOptions) or
                 (toChildrenAbove in FOptions.FPaintOptions)) then
              begin
                if toChildrenAbove in FOptions.FPaintOptions then
                begin
                  NeedFullInvalidate := True;
                  if (PosHoldable and ChildrenInView and NodeInView) or not
                     (toAutoScrollOnExpand in FOptions.FAutoOptions) then
                    SetOffsetY(FOffsetY - Integer(HeightDelta))
                  else
                    if TotalFit and NodeInView then
                    begin
                      FirstVisible := GetFirstVisible(Node, True);
                      if Assigned(FirstVisible) then 
                        SetOffsetY(FOffsetY - GetDisplayRect(FirstVisible, NoColumn, False).Top)
                    end else
                      BottomNode := Node;
                end
                else
                begin
                  
                  if PosHoldable then
                    NeedFullInvalidate := ScrollIntoView(GetLastVisible(Node, True), False)
                  else
                  begin
                    TopNode := Node;
                    NeedFullInvalidate := True;
                  end;
                end;
              end
              else
              begin
                
                if toChildrenAbove in FOptions.FPaintOptions then
                  SetOffsetY(FOffsetY - Integer(HeightDelta));
                NeedFullInvalidate := True;
              end;
            end;
            
            if NeedFullInvalidate then
              Invalidate
            else
              InvalidateToBottom(Node);
          end
          else
            InvalidateNode(Node);
        end
        else
          UpdateRanges;
      end;

    finally
      Exclude(Node.States, vsToggling);
      if not TogglingTree then
        DoStateChange([], [tsToggling]);
    end;
  end;
end;

function TBaseVirtualTree.UpdateAction(Action: TBasicAction): Boolean;

begin
  if not Focused then
    Result := inherited UpdateAction(Action)
  else
  begin
    Result := (Action is TEditCut) or (Action is TEditCopy) or (Action is TEditDelete);

    if Result then
      TAction(Action).Enabled := (FSelectionCount > 0) and ((Action is TEditDelete) or (FClipboardFormats.Count > 0))
    else
    begin
      Result := Action is TEditPaste;
      if Result then
        TAction(Action).Enabled := True
      else
      begin
        Result := Action is TEditSelectAll;
        if Result then
          TAction(Action).Enabled := (toMultiSelect in FOptions.FSelectionOptions) and (FVisibleCount > 0)
        else
          Result := inherited UpdateAction(Action);
      end;
    end;
  end;
end;

procedure TBaseVirtualTree.UpdateHorizontalRange;

begin
  if FHeader.UseColumns then
    FRangeX := FHeader.FColumns.TotalWidth
  else
    FRangeX := GetMaxRightExtend;
end;

procedure TBaseVirtualTree.UpdateHorizontalScrollBar(DoRepaint: Boolean);

var
  ScrollInfo: TScrollInfo;

begin
  UpdateHorizontalRange;

  if tsUpdating in FStates then
    exit;
  
  if UseRightToLeftAlignment then
    FEffectiveOffsetX := Integer(FRangeX) - ClientWidth + FOffsetX
  else
    FEffectiveOffsetX := -FOffsetX;

  if FScrollBarOptions.ScrollBars in [{$if CompilerVersion >=24}System.UITypes.TScrollStyle.{$ifend}ssHorizontal, {$if CompilerVersion >=24}System.UITypes.TScrollStyle.{$ifend}ssBoth] then
  begin
    ZeroMemory (@ScrollInfo, SizeOf(ScrollInfo));
    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_ALL;
    GetScrollInfo(Handle, SB_HORZ, ScrollInfo);

    if (Integer(FRangeX) > ClientWidth) or FScrollBarOptions.AlwaysVisible then
    begin
      DoShowScrollBar(SB_HORZ, True);

      ScrollInfo.nMin := 0;
      ScrollInfo.nMax := FRangeX;
      ScrollInfo.nPos := FEffectiveOffsetX;
      ScrollInfo.nPage := Max(0, ClientWidth + 1);

      ScrollInfo.fMask := SIF_ALL or ScrollMasks[FScrollBarOptions.AlwaysVisible];
      SetScrollInfo(Handle, SB_HORZ, ScrollInfo, DoRepaint);
    end
    else
    begin
      ScrollInfo.nMin := 0;
      ScrollInfo.nMax := 0;
      ScrollInfo.nPos := 0;
      ScrollInfo.nPage := 0;
      DoShowScrollBar(SB_HORZ, False);
      SetScrollInfo(Handle, SB_HORZ, ScrollInfo, False);
    end;
    
    FEffectiveOffsetX := GetScrollPos(Handle, SB_HORZ);
    if UseRightToLeftAlignment then
      SetOffsetX(-Integer(FRangeX) + ClientWidth + FEffectiveOffsetX)
    else
      SetOffsetX(-FEffectiveOffsetX);
  end
  else
  begin
    DoShowScrollBar(SB_HORZ, False);
    
    SetOffsetX(FOffsetX);
  end;
end;

procedure TBaseVirtualTree.UpdateRanges;

begin
  UpdateVerticalRange;
  UpdateHorizontalRange;
end;

procedure TBaseVirtualTree.UpdateScrollBars(DoRepaint: Boolean);

begin
  if HandleAllocated then
  begin
    UpdateVerticalScrollBar(DoRepaint);
    UpdateHorizontalScrollBar(DoRepaint);
  end;
end;

procedure TBaseVirtualTree.UpdateVerticalRange;

begin
  
  if FRoot.TotalHeight < FDefaultNodeHeight then
    FRoot.TotalHeight := FDefaultNodeHeight;
  FRangeY := FRoot.TotalHeight - FRoot.NodeHeight + FBottomSpace;
end;

procedure TBaseVirtualTree.UpdateVerticalScrollBar(DoRepaint: Boolean);

var
  ScrollInfo: TScrollInfo;

begin
  UpdateVerticalRange;

  if tsUpdating in FStates then
    exit;

  if FScrollBarOptions.ScrollBars in [ssVertical, ssBoth] then
  begin
    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_ALL;
    GetScrollInfo(Handle, SB_VERT, ScrollInfo);

    if (Integer(FRangeY) > ClientHeight) or FScrollBarOptions.AlwaysVisible then
    begin
      DoShowScrollBar(SB_VERT, True);

      ScrollInfo.nMin := 0;
      ScrollInfo.nMax := FRangeY;
      ScrollInfo.nPos := -FOffsetY;
      ScrollInfo.nPage := Max(0, ClientHeight + 1);

      ScrollInfo.fMask := SIF_ALL or ScrollMasks[FScrollBarOptions.AlwaysVisible];
      SetScrollInfo(Handle, SB_VERT, ScrollInfo, DoRepaint);
    end
    else
    begin
      ScrollInfo.nMin := 0;
      ScrollInfo.nMax := 0;
      ScrollInfo.nPos := 0;
      ScrollInfo.nPage := 0;
      DoShowScrollBar(SB_VERT, False);
      SetScrollInfo(Handle, SB_VERT, ScrollInfo, False);
    end;
    
    SetOffsetY(-GetScrollPos(Handle, SB_VERT));
  end
  else
  begin
    DoShowScrollbar(SB_VERT, False);
    
    SetOffsetY(FOffsetY);
  end;
end;

function TBaseVirtualTree.UseRightToLeftReading: Boolean;

begin
  Result := BiDiMode <> bdLeftToRight;
end;

procedure TBaseVirtualTree.ValidateChildren(Node: PVirtualNode; Recursive: Boolean);

var
  Child: PVirtualNode;

begin
  if Node = nil then
    Node := FRoot;

  if (vsHasChildren in Node.States) and (Node.ChildCount = 0) then
    InitChildren(Node);
  Child := Node.FirstChild;
  while Assigned(Child) do
  begin
    ValidateNode(Child, Recursive);
    Child := Child.NextSibling;
  end;
end;

procedure TBaseVirtualTree.ValidateNode(Node: PVirtualNode; Recursive: Boolean);

var
  Child: PVirtualNode;

begin
  if Node = nil then
    Node := FRoot
  else
    if not (vsInitialized in Node.States) then
      InitNode(Node);

  if Recursive then
  begin
    if (vsHasChildren in Node.States) and (Node.ChildCount = 0) then
      InitChildren(Node);
    Child := Node.FirstChild;
    while Assigned(Child) do
    begin
      ValidateNode(Child, recursive);
      Child := Child.NextSibling;
    end;
  end;
end;

constructor TCustomStringTreeOptions.Create(AOwner: TBaseVirtualTree);

begin
  inherited;

  FStringOptions := DefaultStringOptions;
end;

procedure TCustomStringTreeOptions.SetStringOptions(const Value: TVTStringOptions);

var
  ChangedOptions: TVTStringOptions;

begin
  if FStringOptions <> Value then
  begin
    
    ChangedOptions := FStringOptions + Value - (FStringOptions * Value);
    FStringOptions := Value;
    with FOwner do
      if (toShowStaticText in ChangedOptions) and not (csLoading in ComponentState) and HandleAllocated then
        Invalidate;
  end;
end;

procedure TCustomStringTreeOptions.AssignTo(Dest: TPersistent);

begin
  if Dest is TCustomStringTreeOptions then
  begin
    with Dest as TCustomStringTreeOptions do
      StringOptions := Self.StringOptions;
  end;
  
  inherited;
end;

constructor TVTEdit.Create(Link: TStringEditLink);

begin
  inherited Create(nil);
  ShowHint := False;
  ParentShowHint := False;
  
  FRefLink := Link;
  
  FLink := Link;
end;

procedure TVTEdit.CMAutoAdjust(var Message: TMessage);

begin
  AutoAdjustSize;
end;

procedure TVTEdit.CMExit(var Message: TMessage);

begin
  if Assigned(FLink) and not FLink.FStopping then
    with FLink, FTree do
    begin
      if (toAutoAcceptEditChange in TreeOptions.StringOptions) then
        DoEndEdit
      else
        DoCancelEdit;
    end;
end;

procedure TVTEdit.CMRelease(var Message: TMessage);

begin
  Free;
end;

procedure TVTEdit.CNCommand(var Message: TWMCommand);

begin
  if Assigned(FLink) and Assigned(FLink.FTree) and (Message.NotifyCode = EN_UPDATE) and
    not (vsMultiline in FLink.FNode.States) then
    
    AutoAdjustSize()
  else
    Inherited;
end;

procedure TVTEdit.WMChar(var Message: TWMChar);

begin
  if not (Message.CharCode in [VK_ESCAPE, VK_TAB]) then
    inherited;
end;

procedure TVTEdit.WMDestroy(var Message: TWMDestroy);

begin
  
  if Assigned(FLink) and not FLink.FStopping then
  begin
    with FLink, FTree do
    begin
      if (toAutoAcceptEditChange in TreeOptions.StringOptions) and Modified then
        Text[FNode, FColumn] := FEdit.Text;
    end;
    FLink := nil;
    FRefLink := nil;
  end;

  inherited;
end;

procedure TVTEdit.WMGetDlgCode(var Message: TWMGetDlgCode);

begin
  inherited;

  Message.Result := Message.Result or DLGC_WANTALLKEYS or DLGC_WANTTAB or DLGC_WANTARROWS;
end;

procedure TVTEdit.WMKeyDown(var Message: TWMKeyDown);

var
  Shift: TShiftState;
  EndEdit: Boolean;
  Tree: TBaseVirtualTree;
  NextNode: PVirtualNode;
begin
  Tree := FLink.FTree;
  case Message.CharCode of
    VK_ESCAPE:
      begin
        Tree.DoCancelEdit;
        Tree.SetFocus;
      end;
    VK_RETURN:
      begin
        EndEdit := not (vsMultiline in FLink.FNode.States);
        if not EndEdit then
        begin
          
          Shift := KeyDataToShiftState(Message.KeyData);
          EndEdit := ssCtrl in Shift;
        end;
        if EndEdit then
        begin
          Tree := FLink.FTree;
          FLink.FTree.InvalidateNode(FLink.FNode);
          FLink.FTree.DoEndEdit;
          Tree.SetFocus;
        end;
      end;
    VK_UP:
      begin
        if not (vsMultiline in FLink.FNode.States) then
          Message.CharCode := VK_LEFT;
        inherited;
      end;
    VK_DOWN:
      begin
        if not (vsMultiline in FLink.FNode.States) then
          Message.CharCode := VK_RIGHT;
        inherited;
      end;
    VK_TAB:
      begin
        if Tree.IsEditing then begin
          Tree.InvalidateNode(FLink.FNode);
          NextNode := Tree.GetNextVisible(FLink.FNode, True);
          Tree.EndEditNode;
          Tree.FocusedNode := NextNode;
          if Tree.CanEdit(Tree.FocusedNode, Tree.FocusedColumn) then
            Tree.DoEdit;
        end;
      end;
    Ord('A'):
      begin
        if Tree.IsEditing and ([ssCtrl] = KeyboardStateToShiftState) then begin
          Self.SelectAll();
          Message.CharCode := 0;
        end;
      end;
  else
    inherited;
  end;
end;

procedure TVTEdit.AutoAdjustSize;

var
  DC: HDC;
  Size: TSize;
  LastFont: THandle;

begin
  if not (vsMultiline in FLink.FNode.States) and not (toGridExtensions in FLink.FTree.FOptions.FMiscOptions) then
  begin
    
    SendMessage(Handle, WM_SETREDRAW, 0, 0);

    DC := GetDC(Handle);
    LastFont := SelectObject(DC, Font.Handle);
    try
      
      {$ifdef TntSupport}
        GetTextExtentPoint32W(DC, PWideChar(Text), Length(Text), Size);
      {$else}
        GetTextExtentPoint32(DC, PChar(Text+'yG'), Length(Text)+2, Size);
      {$endif TntSupport}
      Inc(Size.cx, 2 * FLink.FTree.FTextMargin);
      Inc(Size.cy, 2 * FLink.FTree.FTextMargin);
      Height := Max(Size.cy, Height - 2 * GetSystemMetrics(SM_CYBORDER)); 
      
      if Size.cx < Width then
        FLink.FTree.Invalidate();

      if FLink.FAlignment = taRightJustify then
        FLink.SetBounds(Rect(Left + Width - Size.cx, Top, Left + Width, Top + Height))
      else
        FLink.SetBounds(Rect(Left, Top, Left + Size.cx, Top + Height));
    finally
      SelectObject(DC, LastFont);
      ReleaseDC(Handle, DC);
      SendMessage(Handle, WM_SETREDRAW, 1, 0);
    end;
  end;
end;

procedure TVTEdit.CreateParams(var Params: TCreateParams);

begin
  inherited;
  
  with Params do
  begin
    Style := Style or ES_MULTILINE;
    if vsMultiline in FLink.FNode.States then
      Style := Style and not (ES_AUTOHSCROLL or WS_HSCROLL) or WS_VSCROLL or ES_AUTOVSCROLL;
    if tsUseThemes in FLink.FTree.FStates then
    begin
      Style := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end
    else
    begin
      Style := Style or WS_BORDER;
      ExStyle := ExStyle and not WS_EX_CLIENTEDGE;
    end;
  end;
end;

procedure TVTEdit.Release;

begin
  if HandleAllocated then
    PostMessage(Handle, CM_RELEASE, 0, 0);
end;

constructor TStringEditLink.Create;

begin
  inherited;
  FEdit := TVTEdit.Create(Self);
  with FEdit do
  begin
    Visible := False;
    BorderStyle := bsSingle;
    AutoSize := False;
  end;
end;

destructor TStringEditLink.Destroy;

begin
  FEdit.Release;
  inherited;
end;

function TStringEditLink.BeginEdit: Boolean;

begin
  Result := not FStopping;
  if Result then
  begin
    FEdit.Show;
    FEdit.SelectAll;
    FEdit.SetFocus;
    FEdit.AutoAdjustSize;
  end;
end;

procedure TStringEditLink.SetEdit(const Value: TVTEdit);

begin
  if Assigned(FEdit) then
    FEdit.Free;
  FEdit := Value;
end;

function TStringEditLink.CancelEdit: Boolean;

begin
  Result := not FStopping;
  if Result then
  begin
    FStopping := True;
    FEdit.Hide;
    FTree.CancelEditNode;
    FEdit.FLink := nil;
    FEdit.FRefLink := nil;
  end;
end;

function TStringEditLink.EndEdit: Boolean;

begin
  Result := not FStopping;
  if Result then
  try
    FStopping := True;
    if FEdit.Modified then
      FTree.Text[FNode, FColumn] := FEdit.Text;
    FEdit.Hide;
    FEdit.FLink := nil;
    FEdit.FRefLink := nil;
  except
    FStopping := False;
    raise;
  end;
end;

function TStringEditLink.GetBounds: TRect;

begin
  Result := FEdit.BoundsRect;
end;

function TStringEditLink.PrepareEdit(Tree: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex): Boolean;

var
  Text: UnicodeString;

begin
  Result := Tree is TCustomVirtualStringTree;
  if Result then
  begin
    FTree := Tree as TCustomVirtualStringTree;
    FNode := Node;
    FColumn := Column;
    
    FTree.GetTextInfo(Node, Column, FEdit.Font, FTextBounds, Text);
    FEdit.Font.Color := clWindowText;
    FEdit.Parent := Tree;
    FEdit.RecreateWnd;
    FEdit.HandleNeeded;
    FEdit.Text := Text;

    if Column <= NoColumn then
    begin
      FEdit.BidiMode := FTree.BidiMode;
      FAlignment := FTree.Alignment;
    end
    else
    begin
      FEdit.BidiMode := FTree.Header.Columns[Column].BidiMode;
      FAlignment := FTree.Header.Columns[Column].Alignment;
    end;

    if FEdit.BidiMode <> bdLeftToRight then
      ChangeBidiModeAlignment(FAlignment);
  end;
end;

procedure TStringEditLink.ProcessMessage(var Message: TMessage);

begin
  FEdit.WindowProc(Message);
end;

procedure TStringEditLink.SetBounds(R: TRect);

var
  lOffset: Integer;

begin
  if not FStopping then
  begin
    
    if R.Left < 0 then
      R.Left := 0;
    if R.Right - R.Left < 30 then
    begin
      if FAlignment = taRightJustify then
        R.Left := R.Right - 30
      else
        R.Right := R.Left + 30;
    end;
    if R.Right > FTree.ClientWidth then
      R.Right := FTree.ClientWidth;
    FEdit.BoundsRect := R;
    
    R := FEdit.ClientRect;
    lOffset := IfThen(vsMultiline in FNode.States, 0, 2);
    if tsUseThemes in FTree.FStates then
      Inc(lOffset);
    InflateRect(R, -FTree.FTextMargin + lOffset, lOffset);
    if not (vsMultiline in FNode.States) then
      OffsetRect(R, 0, FTextBounds.Top - FEdit.Top);
    R.Top := Max(-1, R.Top); 
    SendMessage(FEdit.Handle, EM_SETRECTNP, 0, LPARAM(@R));
  end;
end;

constructor TCustomVirtualStringTree.Create(AOwner: TComponent);

begin
  inherited;

  FDefaultText := 'Node';
  FInternalDataOffset := AllocateInternalDataArea(SizeOf(Cardinal));
end;

procedure TCustomVirtualStringTree.GetRenderStartValues(Source: TVSTTextSourceType; var Node: PVirtualNode;
  var NextNodeProc: TGetNextNodeProc);

begin
  case Source of
    tstInitialized:
      begin
        Node := GetFirstInitialized;
        NextNodeProc := GetNextInitialized;
      end;
    tstSelected:
      begin
        Node := GetFirstSelected;
        NextNodeProc := GetNextSelected;
      end;
    tstCutCopySet:
      begin
        Node := GetFirstCutCopy;
        NextNodeProc := GetNextCutCopy;
      end;
    tstVisible:
      begin
        Node := GetFirstVisible(nil, True);
        NextNodeProc := GetNextVisible;
      end;
    tstChecked:
      begin
        Node := GetFirstChecked;
        NextNodeProc := GetNextChecked;
      end;
  else 
    Node := GetFirst;
    NextNodeProc := GetNext;
  end;
end;

procedure TCustomVirtualStringTree.GetDataFromGrid(const AStrings: TStringList;
  const IncludeHeading: Boolean);
var
  LColIndex   : Integer;
  LStartIndex : Integer;
  LAddString  : String;
  LCellText   : String;
  LChildNode  : PVirtualNode;
begin
  
  LStartIndex := 0;
  
  if IncludeHeading then
  begin
    LAddString := EmptyStr;
    for LColIndex := LStartIndex to Pred(Header.Columns.Count) do
    begin
      if (LColIndex > LStartIndex) then
        LAddString  := LAddString + ',';
      LAddString := LAddString + AnsiQuotedStr(Header.Columns.Items[LColIndex].Text, '"');
    end;
    AStrings.Add(LAddString);
  end;
  
  LChildNode := GetFirst;
  while Assigned(LChildNode) do
  begin
    LAddString := EmptyStr;
    
    for LColIndex := LStartIndex to Pred(Header.Columns.Count) do
    begin
      LCellText     := Text[LChildNode, LColIndex];
      if (LCellText = EmptyStr) then
        LCellText   := ' ';
      if (LColIndex > LStartIndex) then
        LAddString  := LAddString + ',';
      LAddString    := LAddString + AnsiQuotedStr(LCellText, '"');
    end;

    AStrings.Add(LAddString);
    LChildNode := LChildNode.NextSibling;
  end;
end;

function TCustomVirtualStringTree.GetImageText(Node: PVirtualNode;
  Kind: TVTImageKind; Column: TColumnIndex): UnicodeString;
begin
  Assert(Assigned(Node), 'Node must not be nil.');

  if not (vsInitialized in Node.States) then
    InitNode(Node);
  Result := '';

  DoGetImageText(Node, Kind, Column, Result);
end;

function TCustomVirtualStringTree.GetOptions: TCustomStringTreeOptions;

begin
  Result := FOptions as TCustomStringTreeOptions;
end;

function TCustomVirtualStringTree.GetStaticText(Node: PVirtualNode; Column: TColumnIndex): UnicodeString;

begin
  Assert(Assigned(Node), 'Node must not be nil.');

  if not (vsInitialized in Node.States) then
    InitNode(Node);
  Result := '';

  DoGetText(Node, Column, ttStatic, Result);
end;

function TCustomVirtualStringTree.GetText(Node: PVirtualNode; Column: TColumnIndex): UnicodeString;

begin
  Assert(Assigned(Node), 'Node must not be nil.');

  if not (vsInitialized in Node.States) then
    InitNode(Node);
  Result := FDefaultText;

  DoGetText(Node, Column, ttNormal, Result);
end;

procedure TCustomVirtualStringTree.InitializeTextProperties(var PaintInfo: TVTPaintInfo);

begin
  with PaintInfo do
  begin
    
    Canvas.Font := Font;
    if Enabled then 
       Canvas.Font.Color :=  FColors.NodeFontColor
    else
      Canvas.Font.Color := FColors.DisabledColor;

    if (toHotTrack in FOptions.FPaintOptions) and (Node = FCurrentHotNode) then
    begin
      if not (tsUseExplorerTheme in FStates) then
      begin
        Canvas.Font.Style := Canvas.Font.Style + [fsUnderline];
        Canvas.Font.Color := FColors.HotColor;
      end;
    end;
    
    if poDrawSelection in PaintOptions then
    begin
      if (Column = FFocusedColumn) or (toFullRowSelect in FOptions.FSelectionOptions) then
      begin
        if Node = FDropTargetNode then
        begin
          if ((FLastDropMode = dmOnNode) or (vsSelected in Node.States)) and not
             (tsUseExplorerTheme in FStates) then
            Canvas.Font.Color := FColors.SelectionTextColor;
        end
        else
          if vsSelected in Node.States then
          begin
            if (Focused or (toPopupMode in FOptions.FPaintOptions)) and not
               (tsUseExplorerTheme in FStates) then
            Canvas.Font.Color := FColors.SelectionTextColor;
          end;
      end;
    end;
  end;
end;

procedure TCustomVirtualStringTree.PaintNormalText(var PaintInfo: TVTPaintInfo; TextOutFlags: Integer;
  Text: UnicodeString);

var
  TripleWidth: Integer;
  R: TRect;
  DrawFormat: Cardinal;
  Size: TSize;
  Height: Integer;

begin
  InitializeTextProperties(PaintInfo);
  with PaintInfo do
  begin
    R := ContentRect;
    Canvas.TextFlags := 0;
    InflateRect(R, -FTextMargin, 0);
    
    if vsMultiline in Node.States then
    begin
      Height  := ComputeNodeHeight(Canvas, Node, Column);
      DoPaintText(Node, Canvas, Column, ttNormal);
      
      if (vsDisabled in Node.States) or not Enabled then
        Canvas.Font.Color := FColors.DisabledColor;
      
      DrawFormat := DT_NOPREFIX or DT_WORDBREAK or DT_END_ELLIPSIS or DT_EDITCONTROL or AlignmentToDrawFlag[Alignment];
      if BidiMode <> bdLeftToRight then
        DrawFormat := DrawFormat or DT_RTLREADING;
      
      if R.Bottom - R.Top > Height then
        InflateRect(R, 0, (Height - R.Bottom - R.Top) div 2);
    end
    else
    begin
      FFontChanged := False;
      TripleWidth := FEllipsisWidth;
      DoPaintText(Node, Canvas, Column, ttNormal);
      if FFontChanged then
      begin
        
        TripleWidth := 0;
        
        GetTextExtentPoint32W(Canvas.Handle, PWideChar(Text), Length(Text), Size);
        NodeWidth := Size.cx + 2 * FTextMargin;
      end;
      
      if (vsDisabled in Node.States) or not Enabled then
        Canvas.Font.Color := FColors.DisabledColor;

      DrawFormat := DT_NOPREFIX or DT_VCENTER or DT_SINGLELINE;
      if BidiMode <> bdLeftToRight then
        DrawFormat := DrawFormat or DT_RTLREADING;
      
      if (Column > -1) and ((NodeWidth - 2 * FTextMargin) > R.Right - R.Left) then
      begin
        Text := DoShortenString(Canvas, Node, Column, Text, R.Right - R.Left, TripleWidth);
        if Alignment = taRightJustify then
          DrawFormat := DrawFormat or DT_RIGHT
        else
          DrawFormat := DrawFormat or DT_LEFT;
      end
      else
        DrawFormat := DrawFormat or AlignmentToDrawFlag[Alignment];
    end;

    if Canvas.TextFlags and ETO_OPAQUE = 0 then
      SetBkMode(Canvas.Handle, TRANSPARENT)
    else
      SetBkMode(Canvas.Handle, OPAQUE);

    DoTextDrawing(PaintInfo, Text, R, DrawFormat);
  end;
end;

procedure TCustomVirtualStringTree.PaintStaticText(const PaintInfo: TVTPaintInfo; TextOutFlags: Integer;
  const Text: UnicodeString);

var
  R: TRect;
  DrawFormat: Cardinal;

begin
  with PaintInfo do
  begin
    Canvas.Font := Font;
    if toFullRowSelect in FOptions.FSelectionOptions then
    begin
      if Node = FDropTargetNode then
      begin
        if (FLastDropMode = dmOnNode) or (vsSelected in Node.States) then
          Canvas.Font.Color := FColors.SelectionTextColor
        else
          Canvas.Font.Color := FColors.NodeFontColor;
      end
      else
        if vsSelected in Node.States then
        begin
          if Focused or (toPopupMode in FOptions.FPaintOptions) then
          Canvas.Font.Color := FColors.SelectionTextColor
          else
            Canvas.Font.Color := FColors.NodeFontColor;
        end;
    end;

    DrawFormat := DT_NOPREFIX or DT_VCENTER or DT_SINGLELINE;
    Canvas.TextFlags := 0;
    DoPaintText(Node, Canvas, Column, ttStatic);
    
    if (vsDisabled in Node.States) or not Enabled then
      Canvas.Font.Color := FColors.DisabledColor;

    R := ContentRect;
    if Alignment = taRightJustify then
      Dec(R.Right, NodeWidth + FTextMargin)
    else
      Inc(R.Left, NodeWidth + FTextMargin);

    if Canvas.TextFlags and ETO_OPAQUE = 0 then
      SetBkMode(Canvas.Handle, TRANSPARENT)
    else
      SetBkMode(Canvas.Handle, OPAQUE);
    Windows.DrawTextW(Canvas.Handle, PWideChar(Text), Length(Text), R, DrawFormat);
  end;
end;

procedure TCustomVirtualStringTree.ReadText(Reader: TReader);

begin
  case Reader.NextValue of
    vaLString, vaString:
      SetDefaultText(Reader.ReadString);
  else
    SetDefaultText(Reader.{$if CompilerVersion >= 23}ReadString{$else}ReadWideString{$ifend});
  end;
end;

function TCustomVirtualStringTree.SaveToCSVFile(
  const FileNameWithPath: TFileName; const IncludeHeading: Boolean): Boolean;
var
  LResultList : TStringList;
begin
  Result := False;
  if (FileNameWithPath = '') then Exit;

  LResultList := TStringList.Create;
  try
    
    GetDataFromGrid(LResultList, IncludeHeading);
    
    LResultList.SaveToFile(FileNameWithPath);
    Result := True;
  finally
    FreeAndNil(LResultList);
  end;
end;

procedure TCustomVirtualStringTree.SetDefaultText(const Value: UnicodeString);

begin
  if FDefaultText <> Value then
  begin
    FDefaultText := Value;
    if not (csLoading in ComponentState) then
      Invalidate;
  end;
end;

procedure TCustomVirtualStringTree.SetOptions(const Value: TCustomStringTreeOptions);

begin
  FOptions.Assign(Value);
end;

procedure TCustomVirtualStringTree.SetText(Node: PVirtualNode; Column: TColumnIndex; const Value: UnicodeString);

begin
  DoNewText(Node, Column, Value);
  InvalidateNode(Node);
end;

procedure TCustomVirtualStringTree.WriteText(Writer: TWriter);

begin
  Writer.{$IF CompilerVersion >= 20}WriteString{$else}WriteWideString{$ifend}(FDefaultText);
end;

procedure TCustomVirtualStringTree.WMSetFont(var Msg: TWMSetFont);

var
  MemDC: HDC;
  Run: PVirtualNode;
  TM: TTextMetric;
  Size: TSize;
  Data: PInteger;

begin
  inherited;

  MemDC := CreateCompatibleDC(0);
  try
    SelectObject(MemDC, Msg.Font);
    GetTextMetrics(MemDC, TM);
    FTextHeight := TM.tmHeight;

    GetTextExtentPoint32W(MemDC, '...', 3, Size);
    FEllipsisWidth := Size.cx;
  finally
    DeleteDC(MemDC);
  end;
  
  Run := FRoot.FirstChild;
  while Assigned(Run) do
  begin
    Data := InternalData(Run);
    if Assigned(Data) then
      Data^ := 0;
    Run := GetNextNoInit(Run);
  end;
end;

procedure TCustomVirtualStringTree.AdjustPaintCellRect(var PaintInfo: TVTPaintInfo; var NextNonEmpty: TColumnIndex);

begin
  if (toAutoSpanColumns in FOptions.FAutoOptions) and FHeader.UseColumns and (PaintInfo.BidiMode = bdLeftToRight) then
    with FHeader.FColumns, PaintInfo do
    begin
      
      NextNonEmpty := GetNextVisibleColumn(Column);
      
      repeat
        if (NextNonEmpty = InvalidColumn) or not ColumnIsEmpty(Node, NextNonEmpty) or
          (Items[NextNonEmpty].BidiMode <> bdLeftToRight) then
          Break;
        Inc(CellRect.Right, Items[NextNonEmpty].Width);
        NextNonEmpty := GetNextVisibleColumn(NextNonEmpty);
      until False;
    end
    else
      inherited;
end;

function TCustomVirtualStringTree.CalculateStaticTextWidth(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  Text: UnicodeString): Integer;

begin
  Result := 0;
  if (Length(Text) > 0) and (Alignment <> taCenter) and not
     (vsMultiline in Node.States) and (toShowStaticText in TreeOptions.FStringOptions) then
  begin
    DoPaintText(Node, Canvas, Column, ttStatic);

    Inc(Result, DoTextMeasuring(Canvas, Node, Column, Text).cx);
    Inc(Result, FTextMargin);
  end;
end;

function TCustomVirtualStringTree.CalculateTextWidth(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  Text: UnicodeString): Integer;

begin
  Result := 2 * FTextMargin;
  if Length(Text) > 0 then
  begin
    Canvas.Font := Font;
    DoPaintText(Node, Canvas, Column, ttNormal);

    Inc(Result, DoTextMeasuring(Canvas, Node, Column, Text).cx);
  end;
end;

function TCustomVirtualStringTree.ColumnIsEmpty(Node: PVirtualNode; Column: TColumnIndex): Boolean;

begin
  Result := Length(Text[Node, Column]) = 0;
  
  if Result then
    Result := inherited ColumnIsEmpty(Node, Column);
end;

procedure TCustomVirtualStringTree.DefineProperties(Filer: TFiler);

begin
  inherited;
  
  Filer.DefineProperty('WideDefaultText', ReadText, WriteText, FDefaultText <> 'Node');
  Filer.DefineProperty('StringOptions', ReadOldStringOptions, nil, False);
end;

function TCustomVirtualStringTree.DoCreateEditor(Node: PVirtualNode; Column: TColumnIndex): IVTEditLink;

begin
  Result := inherited DoCreateEditor(Node, Column);
  
  if Result = nil then
    Result := TStringEditLink.Create;
end;

function TCustomVirtualStringTree.DoGetNodeHint(Node: PVirtualNode; Column: TColumnIndex;
  var LineBreakStyle: TVTTooltipLineBreakStyle): UnicodeString;

begin
  Result := inherited DoGetNodeHint(Node, Column, LineBreakStyle);
  if Assigned(FOnGetHint) then
    FOnGetHint(Self, Node, Column, LineBreakStyle, Result);
end;

function TCustomVirtualStringTree.DoGetNodeTooltip(Node: PVirtualNode; Column: TColumnIndex;
  var LineBreakStyle: TVTTooltipLineBreakStyle): UnicodeString;

begin
  Result := inherited DoGetNodeToolTip(Node, Column, LineBreakStyle);
  if Assigned(FOnGetHint) then
    FOnGetHint(Self, Node, Column, LineBreakStyle, Result)
  else
    Result := Text[Node, Column];
end;

function TCustomVirtualStringTree.DoGetNodeExtraWidth(Node: PVirtualNode; Column: TColumnIndex;
  Canvas: TCanvas = nil): Integer;

begin
    if Canvas = nil then
      Canvas := Self.Canvas;
    Result := CalculateStaticTextWidth(Canvas, Node, Column, StaticText[Node, Column]);
end;

function TCustomVirtualStringTree.DoGetNodeWidth(Node: PVirtualNode; Column: TColumnIndex; Canvas: TCanvas = nil): Integer;

var
  Data: PInteger;

begin
  if (Column > NoColumn) and (vsMultiline in Node.States) then
    Result := FHeader.Columns[Column].Width
  else
  begin
    if Canvas = nil then
      Canvas := Self.Canvas;

    if Column = FHeader.MainColumn then
    begin
      
      Data := InternalData(Node);
      if Assigned(Data) then
      begin
        Result := Data^;
        if Result = 0 then
        begin
          Data^ := CalculateTextWidth(Canvas, Node, Column, Text[Node, Column]);
          Result := Data^;
        end;
      end
      else
        Result := 0;
    end
    else
      
      Result := CalculateTextWidth(Canvas, Node, Column, Text[Node, Column]);
  end;
end;

procedure TCustomVirtualStringTree.DoGetText(Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var Text: UnicodeString);

begin
  if Assigned(FOnGetText) then
    FOnGetText(Self, Node, Column, TextType, Text);
end;

function TCustomVirtualStringTree.DoIncrementalSearch(Node: PVirtualNode; const Text: UnicodeString): Integer;

begin
  Result := 0;
  if Assigned(FOnIncrementalSearch) then
    FOnIncrementalSearch(Self, Node, Text, Result)
  else
    
    if Pos(Text, GetText(Node, FocusedColumn)) <> 1 then
      Result := 1;
end;

procedure TCustomVirtualStringTree.DoNewText(Node: PVirtualNode; Column: TColumnIndex; Text: UnicodeString);

begin
  if Assigned(FOnNewText) then
    FOnNewText(Self, Node, Column, Text);
  
  if FUpdateCount = 0 then
    UpdateHorizontalScrollBar(True);
end;

procedure TCustomVirtualStringTree.DoPaintNode(var PaintInfo: TVTPaintInfo);

var
  S: UnicodeString;
  TextOutFlags: Integer;

begin
  
  RedirectFontChangeEvent(PaintInfo.Canvas);
  try
    
    TextOutFlags := ETO_CLIPPED or RTLFlag[PaintInfo.BidiMode <> bdLeftToRight];
    S := Text[PaintInfo.Node, PaintInfo.Column];
    
    if Length(S) > 0 then
      PaintNormalText(PaintInfo, TextOutFlags, S);
    
    if (Alignment <> taCenter) and not (vsMultiline in PaintInfo.Node.States) and (toShowStaticText in TreeOptions.FStringOptions) then
    begin
      S := '';
      with PaintInfo do
        DoGetText(Node, Column, ttStatic, S);
      if Length(S) > 0 then
        PaintStaticText(PaintInfo, TextOutFlags, S);
    end;
  finally
    RestoreFontChangeEvent(PaintInfo.Canvas);
  end;
end;

procedure TCustomVirtualStringTree.DoPaintText(Node: PVirtualNode; const Canvas: TCanvas; Column: TColumnIndex;
  TextType: TVSTTextType);

begin
  if Assigned(FOnPaintText) then
    FOnPaintText(Self, Canvas, Node, Column, TextType);
end;

function TCustomVirtualStringTree.DoShortenString(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  const S: UnicodeString; Width: Integer; EllipsisWidth: Integer = 0): UnicodeString;

var
  Done: Boolean;

begin
  Done := False;
  if Assigned(FOnShortenString) then
    FOnShortenString(Self, Canvas, Node, Column, S, Width, Result, Done);
  if not Done then
    Result := ShortenString(Canvas.Handle, S, Width, EllipsisWidth);
end;

procedure TCustomVirtualStringTree.DoTextDrawing(var PaintInfo: TVTPaintInfo; Text: UnicodeString; CellRect: TRect;
  DrawFormat: Cardinal);

var
  DefaultDraw: Boolean;

begin
  DefaultDraw := True;
  if Assigned(FOnDrawText) then
    FOnDrawText(Self, PaintInfo.Canvas, PaintInfo.Node, PaintInfo.Column, Text, CellRect, DefaultDraw);
  if DefaultDraw then
    Windows.DrawTextW(PaintInfo.Canvas.Handle, PWideChar(Text), Length(Text), CellRect, DrawFormat);
end;

function TCustomVirtualStringTree.DoTextMeasuring(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  Text: UnicodeString): TSize;

var
  R: TRect;
  DrawFormat: Integer;

begin
  GetTextExtentPoint32W(Canvas.Handle, PWideChar(Text), Length(Text), Result);
  if vsMultiLine in Node.States then
  begin
    DrawFormat := DT_CALCRECT or DT_NOPREFIX or DT_WORDBREAK or DT_END_ELLIPSIS or DT_EDITCONTROL or AlignmentToDrawFlag[Alignment];
    if BidiMode <> bdLeftToRight then
      DrawFormat := DrawFormat or DT_RTLREADING;

    R := Rect(0, 0, Result.cx, MaxInt);
    Windows.DrawTextW(Canvas.Handle, PWideChar(Text), Length(Text), R, DrawFormat);
    Result.cx := R.Right - R.Left;
  end;
  if Assigned(FOnMeasureTextWidth) then
    FOnMeasureTextWidth(Self, Canvas, Node, Column, Text, Result.cx);
  if Assigned(FOnMeasureTextHeight) then
    FOnMeasureTextHeight(Self, Canvas, Node, Column, Text, Result.cy);
end;

function TCustomVirtualStringTree.GetOptionsClass: TTreeOptionsClass;

begin
  Result := TCustomStringTreeOptions;
end;

function TCustomVirtualStringTree.InternalData(Node: PVirtualNode): Pointer;

begin
  if (Node = FRoot) or (Node = nil) then
    Result := nil
  else
    Result := PByte(Node) + FInternalDataOffset;
end;

procedure TCustomVirtualStringTree.MainColumnChanged;

var
  Run: PVirtualNode;
  Data: PInteger;

begin
  inherited;
  
  Run := FRoot.FirstChild;
  while Assigned(Run) do
  begin
    Data := InternalData(Run);
    if Assigned(Data) then
      Data^ := 0;
    Run := GetNextNoInit(Run);
  end;
end;

function TCustomVirtualStringTree.ReadChunk(Stream: TStream; Version: Integer; Node: PVirtualNode; ChunkType,
  ChunkSize: Integer): Boolean;

var
  NewText: UnicodeString;

begin
  case ChunkType of
    CaptionChunk:
      begin
        NewText := '';
        if ChunkSize > 0 then
        begin
          SetLength(NewText, ChunkSize div 2);
          Stream.Read(PWideChar(NewText)^, ChunkSize);
        end;
        
        Text[Node, FHeader.MainColumn] := NewText;
        Result := True;
      end;
  else
    Result := inherited ReadChunk(Stream, Version, Node, ChunkType, ChunkSize);
  end;
end;

type
  TOldVTStringOption = (soSaveCaptions, soShowStaticText);

procedure TCustomVirtualStringTree.ReadOldStringOptions(Reader: TReader);

var
  OldOption: TOldVTStringOption;
  EnumName: string;

begin
  
  UpdateDesigner;
  
  if Reader.ReadValue = vaSet then
    with TreeOptions do
    begin
      
      StringOptions := [];

      while True do
      begin
        
        EnumName := Reader.ReadStr;
        if EnumName = '' then
          Break;
        OldOption := TOldVTStringOption(GetEnumValue(TypeInfo(TOldVTStringOption), EnumName));
        case OldOption of
          soSaveCaptions:
            StringOptions := FStringOptions + [toSaveCaptions];
          soShowStaticText:
            StringOptions := FStringOptions + [toShowStaticText];
        end;
      end;
    end;
end;

function TCustomVirtualStringTree.RenderOLEData(const FormatEtcIn: TFormatEtc; out Medium: TStgMedium;
  ForClipboard: Boolean): HResult;

begin
  Result := inherited RenderOLEData(FormatEtcIn, Medium, ForClipboard);
  if Failed(Result) then
  try
    if ForClipboard then
      Medium.hGlobal := ContentToClipboard(FormatEtcIn.cfFormat, tstCutCopySet)
    else
      Medium.hGlobal := ContentToClipboard(FormatEtcIn.cfFormat, tstSelected);
    
    if Medium.hGlobal <> 0 then
    begin
      Medium.tymed := TYMED_HGLOBAL;
      Medium.unkForRelease := nil;

      Result := S_OK;
    end;
  except
    Result := E_FAIL;
  end;
end;

procedure TCustomVirtualStringTree.WriteChunks(Stream: TStream; Node: PVirtualNode);

var
  Header: TChunkHeader;
  S: UnicodeString;
  Len: Integer;

begin
  inherited;
  if (toSaveCaptions in TreeOptions.FStringOptions) and (Node <> FRoot) and
    (vsInitialized in Node.States) then
    with Stream do
    begin
      
      S := Text[Node, FHeader.MainColumn];
      Len := 2 * Length(S);
      if Len > 0 then
      begin
        
        Header.ChunkType := CaptionChunk;
        Header.ChunkSize := Len;
        Write(Header, SizeOf(Header));
        Write(PWideChar(S)^, Len);
      end;
    end;
end;

function TCustomVirtualStringTree.ComputeNodeHeight(Canvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  S: UnicodeString): Integer;

var
  DrawFormat: Cardinal;
  BidiMode: TBidiMode;
  Alignment: TAlignment;
  PaintInfo: TVTPaintInfo;
  Dummy: TColumnIndex;
  LineImage: TLineImage;
begin
  if Length(S) = 0 then
    S := Text[Node, Column];
  DrawFormat := DT_TOP or DT_NOPREFIX or DT_CALCRECT or DT_WORDBREAK;
  if Column <= NoColumn then
  begin
    BidiMode := Self.BidiMode;
    Alignment := Self.Alignment;
  end
  else
  begin
    BidiMode := Header.Columns[Column].BidiMode;
    Alignment := Header.Columns[Column].Alignment;
  end;

  if BidiMode <> bdLeftToRight then
    ChangeBidiModeAlignment(Alignment);
  
  PaintInfo.Node := Node;
  PaintInfo.BidiMode := BidiMode;
  PaintInfo.Column := Column;
  PaintInfo.CellRect := Rect(0, 0, 0, 0);
  if Column > NoColumn then
  begin
    PaintInfo.CellRect.Right := FHeader.Columns[Column].Width - FTextMargin;
    PaintInfo.CellRect.Left := FTextMargin + FMargin;
    if Column = Header.MainColumn then
    begin
      if toFixedIndent in FOptions.FPaintOptions then
        SetLength(LineImage, 1)
      else
        DetermineLineImageAndSelectLevel(Node, LineImage);
    Inc(PaintInfo.CellRect.Left, Length(LineImage) * Integer(Indent));
    end;
  end
  else
    PaintInfo.CellRect.Right := ClientWidth;
  AdjustPaintCellRect(PaintInfo, Dummy);

  if BidiMode <> bdLeftToRight then
    DrawFormat := DrawFormat or DT_RIGHT or DT_RTLREADING
  else
    DrawFormat := DrawFormat or DT_LEFT;
  Windows.DrawTextW(Canvas.Handle, PWideChar(S), Length(S), PaintInfo.CellRect, DrawFormat);
  Result := PaintInfo.CellRect.Bottom - PaintInfo.CellRect.Top;
end;

function TCustomVirtualStringTree.ContentToClipboard(Format: Word; Source: TVSTTextSourceType): HGLOBAL;

  procedure MakeFragment(var HTML: AnsiString);

  const
    Version = 'Version:1.0'#13#10;
    StartHTML = 'StartHTML:';
    EndHTML = 'EndHTML:';
    StartFragment = 'StartFragment:';
    EndFragment = 'EndFragment:';
    DocType = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">';
    HTMLIntro = '<html><head><META http-equiv=Content-Type content="text/html; charset=utf-8">' +
      '</head><body><!--StartFragment-->';
    HTMLExtro = '<!--EndFragment--></body></html>';
    NumberLengthAndCR = 10;
    
    DescriptionLength = Length(Version) + Length(StartHTML) + Length(EndHTML) + Length(StartFragment) +
      Length(EndFragment) + 4 * NumberLengthAndCR;

  var
    Description: AnsiString;
    StartHTMLIndex,
    EndHTMLIndex,
    StartFragmentIndex,
    EndFragmentIndex: Integer;

  begin
    
    StartHTMLIndex := DescriptionLength;              
    StartFragmentIndex := StartHTMLIndex + Length(DocType) + Length(HTMLIntro);
    EndFragmentIndex := StartFragmentIndex + Length(HTML);
    EndHTMLIndex := EndFragmentIndex + Length(HTMLExtro);

    Description := Version +
    SysUtils.Format('%s%.8d', [StartHTML, StartHTMLIndex]) + #13#10 +
    SysUtils.Format('%s%.8d', [EndHTML, EndHTMLIndex]) + #13#10 +
    SysUtils.Format('%s%.8d', [StartFragment, StartFragmentIndex]) + #13#10 +
    SysUtils.Format('%s%.8d', [EndFragment, EndFragmentIndex]) + #13#10;
    HTML := Description + DocType + HTMLIntro + HTML + HTMLExtro;
  end;

var
  Data: Pointer;
  DataSize: Cardinal;
  S: AnsiString;
  WS: UnicodeString;
  P: Pointer;

begin
  Result := 0;
  case Format of
    CF_TEXT:
      begin
        S := ContentToText(Source, #9) + #0;
        Data := PAnsiChar(S);
        DataSize := Length(S);
      end;
    CF_UNICODETEXT:
      begin
        WS := ContentToUnicode(Source, #9) + #0;
        Data := PWideChar(WS);
        DataSize := 2 * Length(WS);
      end;
  else
    if Format = CF_CSV then
      S := ContentToText(Source, AnsiChar ({$if CompilerVersion>=22}FormatSettings.{$ifend}ListSeparator)) + #0
    else
      if (Format = CF_VRTF) or (Format = CF_VRTFNOOBJS) then
        S := ContentToRTF(Source) + #0
      else
        if Format = CF_HTML then
        begin
          S := ContentToHTML(Source);
          
          MakeFragment(S);
          S := S + #0;
        end;
    Data := PAnsiChar(S);
    DataSize := Length(S);
  end;

  if DataSize > 0 then
  begin
    Result := GlobalAlloc(GHND or GMEM_SHARE, DataSize);
    P := GlobalLock(Result);
    Move(Data^, P^, DataSize);
    GlobalUnlock(Result);
  end;
end;

function TCustomVirtualStringTree.ContentToHTML(Source: TVSTTextSourceType; Caption: UnicodeString = ''): RawByteString;

type
  UCS2 = Word;
  UCS4 = Cardinal;

const
  MaximumUCS4: UCS4 = $7FFFFFFF;
  ReplacementCharacter: UCS4 = $0000FFFD;

var
  Buffer: TBufferedAnsiString;

  function ConvertSurrogate(S1, S2: UCS2): UCS4;

  const
    SurrogateOffset = ($D800 shl 10) + $DC00 - $10000;

  begin
    Result := Word(S1) shl 10 + Word(S2) - SurrogateOffset;
  end;

  function UTF16ToUTF8(const S: UnicodeString): AnsiString;

  const
    FirstByteMark: array[0..6] of Byte = ($00, $00, $C0, $E0, $F0, $F8, $FC);

  var
    Ch: UCS4;
    I, J, T: Integer;
    BytesToWrite: Cardinal;

  begin
    if Length(S) = 0 then
      Result := ''
    else
    begin
      
      SetLength(Result, 6 * Length(S));
      T := 1;
      I := 1;
      while I <= Length(S) do
      begin
        Ch := UCS4(S[I]);
        
        if (Ch and $FFFFF800) = $D800 then
        begin
          Inc(I);
          
          if (I <= Length(S)) and ((UCS4(S[I]) and $FFFFFC00) = $DC00) then
            Ch := ConvertSurrogate(UCS2(Ch), UCS2(S[I]))
          else 
            Continue;
        end;

        if Ch < $80 then
          BytesToWrite := 1
        else
          if Ch < $800 then
            BytesToWrite := 2
          else
            if Ch < $10000 then
              BytesToWrite := 3
            else
              if Ch < $200000 then
                BytesToWrite := 4
              else
                if Ch < $4000000 then
                  BytesToWrite := 5
                else
                  if Ch <= MaximumUCS4 then
                    BytesToWrite := 6
                  else
                  begin
                    BytesToWrite := 2;
                    Ch := ReplacementCharacter;
                  end;

        for J := BytesToWrite downto 2 do
        begin
          Result[T + J - 1] := AnsiChar((Ch or $80) and $BF);
          Ch := Ch shr 6;
        end;
        Result[T] := AnsiChar(Ch or FirstByteMark[BytesToWrite]);
        Inc(T, BytesToWrite);

        Inc(I);
      end;
      SetLength(Result, T - 1); 
    end;
  end;

  procedure WriteColorAsHex(Color: TColor);

  var
    WinColor: COLORREF;
    I: Integer;
    Component,
    Value: Byte;

  begin
    Buffer.Add('#');
    WinColor := ColorToRGB(Color);
    I := 1;
    while I <= 6 do
    begin
      Component := WinColor and $FF;

      Value := 48 + (Component shr 4);
      if Value > $39 then
        Inc(Value, 7);
      Buffer.Add(AnsiChar(Value));
      Inc(I);

      Value := 48 + (Component and $F);
      if Value > $39 then
        Inc(Value, 7);
      Buffer.Add(AnsiChar(Value));
      Inc(I);

      WinColor := WinColor shr 8;
    end;
  end;

  procedure WriteStyle(Name: AnsiString; Font: TFont);

  begin
    if Length(Name) = 0 then
      Buffer.Add(' style="{')
    else
    begin
      Buffer.Add('.');
      Buffer.Add(Name);
      Buffer.Add('{');
    end;

    Buffer.Add(Format('font-family: ''%s''; ', [Font.Name]));
    if Font.Size < 0 then
      Buffer.Add(Format('font-size: %dpx; ', [Font.Height]))
    else
      Buffer.Add(Format('font-size: %dpt; ', [Font.Size]));

    Buffer.Add(Format('font-style: %s; ', [IfThen(fsItalic in Font.Style, 'italic', 'normal')]));
    Buffer.Add(Format('font-weight: %s; ', [IfThen(fsBold in Font.Style, 'bold', 'normal')]));
    Buffer.Add(Format('text-decoration: %s; ', [IfThen(fsUnderline in Font.Style, 'underline', 'none')]));

    Buffer.Add('color: ');
    WriteColorAsHex(Font.Color);
    Buffer.Add(';}');
    if Length(Name) = 0 then
      Buffer.Add('"');
  end;

var
  I, J : Integer;
  Level, MaxLevel: Cardinal;
  AddHeader: AnsiString;
  Save, Run: PVirtualNode;
  GetNextNode: TGetNextNodeProc;
  Text: UnicodeString;

  RenderColumns: Boolean;
  Columns: TColumnsArray;
  ColumnColors: array of AnsiString;
  Index: Integer;
  IndentWidth,
  LineStyleText: AnsiString;
  Alignment: TAlignment;
  BidiMode: TBidiMode;

  CellPadding: AnsiString;

begin
  Buffer := TBufferedAnsiString.Create;
  try
    
    RedirectFontChangeEvent(Canvas);

    CellPadding := Format('padding-left:%dpx;padding-right:%0:dpx;', [FMargin]);

    IndentWidth := IntToStr(FIndent);
    AddHeader := ' ';
    
    if Length(Caption) > 0 then
      AddHeader := AddHeader + 'caption="' + UTF16ToUTF8(Caption) + '"';
    if Borderstyle <> bsNone then
      AddHeader := AddHeader + Format(' border="%d" frame=box', [BorderWidth + 1]);

    Buffer.Add('<META http-equiv="Content-Type" content="text/html; charset=utf-8">');
    
    Buffer.Add('<style type="text/css">');
    Buffer.AddnewLine;
    WriteStyle('default', Font);
    Buffer.AddNewLine;
    WriteStyle('header', FHeader.Font);
    Buffer.AddNewLine;
    
    if FLineStyle = lsSolid then
      LineStyleText := 'solid;'
    else
      LineStyleText := 'dotted;';
    if toShowHorzGridLines in FOptions.FPaintOptions then
    begin
      Buffer.Add('.noborder{border-style:');
      Buffer.Add(LineStyleText);
      Buffer.Add(' border-bottom:1;border-left:0;border-right:0; border-top:0;');
      Buffer.Add(CellPadding);
      Buffer.Add('}');
    end
    else
    begin
      Buffer.Add('.noborder{border-style:none;');
      Buffer.Add(CellPadding);
      Buffer.Add('}');
    end;
    Buffer.AddNewLine;

    Buffer.Add('.normalborder {border-top:none; border-left:none; vertical-align:top;');
    if toShowVertGridLines in FOptions.FPaintOptions then
      Buffer.Add('border-right:1 ' + LineStyleText)
    else
      Buffer.Add('border-right:none;');
    if toShowHorzGridLines in FOptions.FPaintOptions then
      Buffer.Add('border-bottom:1 ' + LineStyleText)
    else
      Buffer.Add('border-bottom:none;');
    Buffer.Add(CellPadding);
    Buffer.Add('}');
    Buffer.Add('</style>');
    Buffer.AddNewLine;
    
    Buffer.Add('<table class="default" bgcolor=');
    WriteColorAsHex(Color);
    Buffer.Add(AddHeader);
    Buffer.Add(' cellspacing="0" cellpadding=');
    Buffer.Add(IntToStr(FMargin) + '>');
    Buffer.AddNewLine;

    Columns := nil;
    ColumnColors := nil;
    RenderColumns := FHeader.UseColumns;
    if RenderColumns then
    begin
      Columns := FHeader.FColumns.GetVisibleColumns;
      SetLength(ColumnColors, Length(Columns));
    end;

    GetRenderStartValues(Source, Run, GetNextNode);
    Save := Run;

    MaxLevel := 0;
    
    while Assigned(Run) do
    begin
      if (CanExportNode(Run)) then
      begin
          Level := GetNodeLevel(Run);
          if Level > MaxLevel then
            MaxLevel := Level;
      end;
      Run := GetNextNode(Run);
    end;

    if RenderColumns then
    begin
      if Assigned(FOnBeforeHeaderExport) then
        FOnBeforeHeaderExport(Self, etHTML);
      Buffer.Add('<tr class="header" style="');
      Buffer.Add(CellPadding);
      Buffer.Add('">');
      Buffer.AddNewLine;
      
      for I := 0 to High(Columns) do
      begin
        if Assigned(FOnBeforeColumnExport) then
            FOnBeforeColumnExport(Self, etHTML, Columns[I]);
        Buffer.Add('<th height="');
        Buffer.Add(IntToStr(FHeader.FHeight));
        Buffer.Add('px"');
        Alignment := Columns[I].CaptionAlignment;
        
        if Columns[I].FBiDiMode <> bdLeftToRight then
        begin
          ChangeBidiModeAlignment(Alignment);
          Buffer.Add(' dir="rtl"');
        end;
          
        case Alignment of
          taRightJustify:
            Buffer.Add(' align=right');
          taCenter:
            Buffer.Add(' align=center');
        else
          Buffer.Add(' align=left');
        end;

        Index := Columns[I].Index;
        
        if (MaxLevel > 0) and (Index = Header.MainColumn) then
        begin
          Buffer.Add(' colspan="');
          Buffer.Add(IntToStr(MaxLevel + 1));
          Buffer.Add('"');
        end;
        
        Buffer.Add(' bgcolor=');
        WriteColorAsHex(clBtnFace);
        
        Buffer.Add(' width="');
        Buffer.Add(IntToStr(Columns[I].Width));
        Buffer.Add('px">');

        if Length(Columns[I].Text) > 0 then
          Buffer.Add(UTF16ToUTF8(Columns[I].Text));
        Buffer.Add('</th>');
        if Assigned(FOnAfterColumnExport) then
            FOnAfterColumnExport(Self, etHTML, Columns[I]);
      end;
      Buffer.Add('</tr>');
      Buffer.AddNewLine;
      if Assigned(FOnAfterHeaderExport) then
        FOnAfterHeaderExport(self, etHTML);
    end;
    
    Run := Save;
    while Assigned(Run) do
    begin
      if ((not CanExportNode(Run)) or (Assigned(FonBeforeNodeExport) and (not FOnBeforeNodeExport(Self, etHTML, Run)))) then
      begin
        Run := GetNextNode(Run);
        Continue;
      end;
      Level := GetNodeLevel(Run);
      Buffer.Add(' <tr class="default">');
      Buffer.AddNewLine;

      I := 0;
      while (I < Length(Columns)) or not RenderColumns do
      begin
        if RenderColumns then
          Index := Columns[I].Index
        else
          Index := NoColumn;

        if not RenderColumns or (coVisible in Columns[I].FOptions) then
        begin
          
          Canvas.Font := Font;
          FFontChanged := False;
          DoPaintText(Run, Canvas, Index, ttNormal);

          if Index = Header.MainColumn then
          begin
            
            if RenderColumns and not (coParentColor in Columns[I].FOptions) then
            begin
              for J := 1 to Level do
              begin
                Buffer.Add('<td class="noborder" width="');
                Buffer.Add(IndentWidth);
                Buffer.Add('" height="');
                Buffer.Add(IntToStr(NodeHeight[Run]));
                Buffer.Add('px"');
                if not (coParentColor in Columns[I].FOptions) then
                begin
                  Buffer.Add(' bgcolor=');
                  WriteColorAsHex(Columns[I].Color);
                end;
                Buffer.Add('>&nbsp;</td>');
              end;
            end
            else
            begin
              for J := 1 to Level do
                if J = 1 then
                begin
                  Buffer.Add(' <td height="');
                  Buffer.Add(IntToStr(NodeHeight[Run]));
                  Buffer.Add('px" class="normalborder">&nbsp;</td>');
                end
                else
                  Buffer.Add(' <td>&nbsp;</td>');
            end;
          end;

          if FFontChanged then
          begin
            Buffer.Add(' <td class="normalborder" ');
            WriteStyle('', Canvas.Font);
            Buffer.Add(' height="');
            Buffer.Add(IntToStr(NodeHeight[Run]));
            Buffer.Add('px"');
          end
          else
          begin
            Buffer.Add(' <td class="normalborder"  height="');
            Buffer.Add(IntToStr(NodeHeight[Run]));
            Buffer.Add('px"');
          end;

          if RenderColumns then
          begin
            Alignment := Columns[I].Alignment;
            BidiMode := Columns[I].BidiMode;
          end
          else
          begin
            Alignment := Self.Alignment;
            BidiMode := Self.BidiMode;
          end;
          
          if BiDiMode <> bdLeftToRight then
          begin
            ChangeBidiModeAlignment(Alignment);
            Buffer.Add(' dir="rtl"');
          end;
          
          case Alignment of
            taRightJustify:
              Buffer.Add(' align=right');
            taCenter:
              Buffer.Add(' align=center');
          else
            Buffer.Add(' align=left');
          end;
          
          if (MaxLevel > 0) and (Index = FHeader.MainColumn) and (Level < MaxLevel) then
          begin
            Buffer.Add(' colspan="');
            Buffer.Add(IntToStr(MaxLevel - Level + 1));
            Buffer.Add('"');
          end;
          if RenderColumns and not (coParentColor in Columns[I].FOptions) then
          begin
            Buffer.Add(' bgcolor=');
            WriteColorAsHex(Columns[I].Color);
          end;
          Buffer.Add('>');
          Text := Self.Text[Run, Index];
          if Length(Text) > 0 then
          begin
            Text := UTF16ToUTF8(Text);
            Buffer.Add(Text);
          end;
          Buffer.Add('</td>');
        end;

        if not RenderColumns then
          Break;
        Inc(I);
      end;
      if Assigned(FOnAfterNodeExport) then
        FOnAfterNodeExport(Self, etHTML, Run);
      Run := GetNextNode(Run);
      Buffer.Add(' </tr>');
      Buffer.AddNewLine;
    end;
    Buffer.Add('</table>');

    RestoreFontChangeEvent(Canvas);

    Result := Buffer.AsString;
  finally
    Buffer.Free;
  end;
end;

function TCustomVirtualStringTree.CanExportNode(Node: PVirtualNode ): Boolean;

begin
  Result := True;
  case FOptions.ExportMode of
    emChecked:
      Result := Node.CheckState = csCheckedNormal;
    emUnchecked:
      Result := Node.CheckState = csUncheckedNormal;
  end;
end;

function TCustomVirtualStringTree.ContentToRTF(Source: TVSTTextSourceType): RawByteString;

var
  Fonts: TStringList;
  Colors: TList;
  CurrentFontIndex,
  CurrentFontColor,
  CurrentFontSize: Integer;
  Buffer: TBufferedAnsiString;

  procedure SelectFont(Font: string);

  var
    I: Integer;

  begin
    I := Fonts.IndexOf(Font);
    if I > -1 then
    begin
      
      if I <> CurrentFontIndex then
      begin
        Buffer.Add('\f');
        Buffer.Add(IntToStr(I));
        CurrentFontIndex := I;
      end;
    end
    else
    begin
      I := Fonts.Add(Font);
      Buffer.Add('\f');
      Buffer.Add(IntToStr(I));
      CurrentFontIndex := I;
    end;
  end;

  procedure SelectColor(Color: TColor);

  var
    I: Integer;

  begin
    I := Colors.IndexOf(Pointer(Color));
    if I > -1 then
    begin
      
      if I <> CurrentFontColor then
      begin
        Buffer.Add('\cf');
        Buffer.Add(IntToStr(I + 1));
        CurrentFontColor := I;
      end;
    end
    else
    begin
      I := Colors.Add(Pointer(Color));
      Buffer.Add('\cf');
      Buffer.Add(IntToStr(I + 1));
      CurrentFontColor := I;
    end;
  end;

  procedure TextPlusFont(Text: UnicodeString; Font: TFont);

  var
    UseUnderline,
    UseItalic,
    UseBold: Boolean;
    I: Integer;

  begin
    if Length(Text) > 0 then
    begin
      UseUnderline := fsUnderline in Font.Style;
      if UseUnderline then
        Buffer.Add('\ul');
      UseItalic := fsItalic in Font.Style;
      if UseItalic then
        Buffer.Add('\i');
      UseBold := fsBold in Font.Style;
      if UseBold then
        Buffer.Add('\b');
      SelectFont(Font.Name);
      SelectColor(Font.Color);
      if Font.Size <> CurrentFontSize then
      begin
        
        Buffer.Add('\fs');
        Buffer.Add(IntToStr(2 * Font.Size));
        CurrentFontSize := Font.Size;
      end;
      
      Buffer.Add(' ');
      
      for I := 1 to Length(Text) do
      begin
        if (Text[I] = WideLF) then
          Buffer.Add( '{\par}' )
        else
          if (Text[i] <> WideCR) then
          begin
            Buffer.Add(Format('\u%d\''3f', [SmallInt(Text[I])]));
            Continue;
          end;
      end;
      if UseUnderline then
        Buffer.Add('\ul0');
      if UseItalic then
        Buffer.Add('\i0');
      if UseBold then
        Buffer.Add('\b0');
    end;
  end;

var
  Level, LastLevel: Integer;
  I, J: Integer;
  Save, Run: PVirtualNode;
  GetNextNode: TGetNextNodeProc;
  S, Tabs : RawByteString;
  Text: UnicodeString;
  Twips: Integer;

  RenderColumns: Boolean;
  Columns: TColumnsArray;
  Index: Integer;
  Alignment: TAlignment;
  BidiMode: TBidiMode;
  LocaleBuffer: Array [0..1] of Char;

begin
  Buffer := TBufferedAnsiString.Create;
  try
    
    RedirectFontChangeEvent(Canvas);

    Fonts := TStringList.Create;
    Colors := TList.Create;
    CurrentFontIndex := -1;
    CurrentFontColor := -1;
    CurrentFontSize := -1;

    Columns := nil;
    Tabs := '';
    LastLevel := 0;

    RenderColumns := FHeader.UseColumns;
    if RenderColumns then
      Columns := FHeader.FColumns.GetVisibleColumns;

    GetRenderStartValues(Source, Run, GetNextNode);
    Save := Run;
    
    Buffer.Add('\uc1\trowd\trgaph70');
    J := 0;
    if RenderColumns then
    begin
      for I := 0 to High(Columns) do
      begin
        Inc(J, Columns[I].Width);
        
        Twips := Round(1440 * J / Screen.PixelsPerInch);
        Buffer.Add('\cellx');
        Buffer.Add(IntToStr(Twips));
      end;
    end
    else
    begin
      Twips := Round(1440 * ClientWidth / Screen.PixelsPerInch);
      Buffer.Add('\cellx');
      Buffer.Add(IntToStr(Twips));
    end;
    
    if RenderColumns then
    begin
      if Assigned(FOnBeforeHeaderExport) then
        FonBeforeHeaderExport(Self, etRTF);
      Buffer.Add('\pard\intbl');
      for I := 0 to High(Columns) do
      begin
        if Assigned(FOnBeforeColumnExport) then
          FOnBeforeColumnExport(Self, etRTF, Columns[I]);
        Alignment := Columns[I].CaptionAlignment;
        BidiMode := Columns[I].BidiMode;
        
        if BidiMode <> bdLeftToRight then
          ChangeBidiModeAlignment(Alignment);
        case Alignment of
          taLeftJustify:
            Buffer.Add('\ql');
          taRightJustify:
            Buffer.Add('\qr');
          taCenter:
            Buffer.Add('\qc');
        end;

        TextPlusFont(Columns[I].Text, Header.Font);
        Buffer.Add('\cell');
        if Assigned(FOnAfterColumnExport) then
          FOnAfterColumnExport( self, etRTF, Columns[I] );
      end;
      Buffer.Add('\row');
      if Assigned(FOnAfterHeaderExport) then
        FOnAfterHeaderExport(Self, etRTF);
    end;
    
    Run := Save;
    while Assigned(Run) do
    begin
      if ((not CanExportNode(Run)) or
         (Assigned(FOnBeforeNodeExport) and (not FOnBeforeNodeExport(Self, etRTF, Run)))) then
      begin
        Run := GetNextNode(Run);
        Continue;
      end;
      I := 0;
      while not RenderColumns or (I < Length(Columns)) do
      begin
        if RenderColumns then
        begin
          Index := Columns[I].Index;
          Alignment := Columns[I].Alignment;
          BidiMode := Columns[I].BidiMode;
        end
        else
        begin
          Index := NoColumn;
          Alignment := FAlignment;
          BidiMode := Self.BidiMode;
        end;

        if not RenderColumns or (coVisible in Columns[I].Options) then
        begin
          Text := Self.Text[Run, Index];
          Buffer.Add('\pard\intbl');
          
          if BidiMode <> bdLeftToRight then
            ChangeBidiModeAlignment(Alignment);
          case Alignment of
            taRightJustify:
              Buffer.Add('\qr');
            taCenter:
              Buffer.Add('\qc');
          end;
          
          Canvas.Font := Font;
          FFontChanged := False;
          DoPaintText(Run, Canvas, Index, ttNormal);

          if Index = Header.MainColumn then
          begin
            Level := GetNodeLevel(Run);
            if Level <> LastLevel then
            begin
              LastLevel := Level;
              Tabs := '';
              for J := 0 to Level - 1 do
                Tabs := Tabs + '\tab';
            end;
            if Level > 0 then
            begin
              Buffer.Add(Tabs);
              Buffer.Add(' ');
              TextPlusFont(Text, Canvas.Font);
              Buffer.Add('\cell');
            end
            else
            begin
              TextPlusFont(Text, Canvas.Font);
              Buffer.Add('\cell');
            end;
          end
          else
          begin
            TextPlusFont(Text, Canvas.Font);
            Buffer.Add('\cell');
          end;
        end;

        if not RenderColumns then
          Break;
        Inc(I);
      end;
      Buffer.Add('\row');
      Buffer.AddNewLine;
      if (Assigned(FOnAfterNodeExport)) then
        FOnAfterNodeExport(Self, etRTF, Run);
      Run := GetNextNode(Run);
    end;

    Buffer.Add('\pard\par');
    
    S := '{\rtf1\ansi\ansicpg1252\deff0\deflang1043{\fonttbl';
    for I := 0 to Fonts.Count - 1 do
      S := S + Format('{\f%d %s;}', [I, Fonts[I]]);
    S := S + '}';

    S := S + '{\colortbl;';
    for I := 0 to Colors.Count - 1 do
    begin
      J := ColorToRGB(TColor(Colors[I]));
      S := S + Format('\red%d\green%d\blue%d;', [J and $FF, (J shr 8) and $FF, (J shr 16) and $FF]);
    end;
    S := S + '}';
    if (GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_IMEASURE, @LocaleBuffer, Length(LocaleBuffer)) <> 0) and (LocaleBuffer[0] = '0') then
      S := S + '\paperw16840\paperh11907'
    else
      S := S + '\paperw15840\paperh12240';
    
    S := S + '\margl720\margr720\margt720\margb720';
    Result := S + Buffer.AsString + '}';
    Fonts.Free;
    Colors.Free;

    RestoreFontChangeEvent(Canvas);
  finally
    Buffer.Free;
  end;
end;

procedure TCustomVirtualStringTree.ContentToCustom(Source: TVSTTextSourceType);

var
  I: Integer;
  Save, Run: PVirtualNode;
  GetNextNode: TGetNextNodeProc;
  RenderColumns: Boolean;
  Columns: TColumnsArray;

begin
  Columns := nil;
  GetRenderStartValues(Source, Run, GetNextNode);
  Save := Run;

  RenderColumns := FHeader.UseColumns and ( hoVisible in FHeader.Options );

  if Assigned(FOnBeforeTreeExport) then
    FOnBeforeTreeExport(Self, etCustom);
  
  if RenderColumns then
  begin
    if Assigned(FOnBeforeHeaderExport) then
      FOnBeforeHeaderExport(Self, etCustom);

    Columns := FHeader.FColumns.GetVisibleColumns;
    for I := 0 to High(Columns) do
    begin
      if Assigned(FOnBeforeColumnExport) then
        FOnBeforeColumnExport(Self, etCustom, Columns[I]);

      if Assigned(FOnColumnExport) then
        FOnColumnExport(Self, etCustom, Columns[I]);

      if Assigned(FOnAfterColumnExport) then
        FOnAfterColumnExport(Self, etCustom, Columns[I]);
    end;

    if Assigned(FOnAfterHeaderExport) then
      FOnAfterHeaderExport(Self, etCustom);
  end;
  
  Run := Save;
  while Assigned(Run) do
  begin
    if CanExportNode(Run) then
    begin
      if Assigned(FOnBeforeNodeExport) then
        FOnBeforeNodeExport(Self, etCustom, Run);

      if Assigned(FOnNodeExport) then
        FOnNodeExport(Self, etCustom, Run);

      if Assigned(FOnAfterNodeExport) then
        FOnAfterNodeExport(Self, etCustom, Run);
    end;

    Run := GetNextNode(Run);
  end;

  if Assigned(FOnAfterTreeExport) then
    FOnAfterTreeExport(Self, etCustom);
end;

function TCustomVirtualStringTree.ContentToText(Source: TVSTTextSourceType; Separator: Char): AnsiString;

begin
  Result := ContentToText(Source, AnsiString(Separator));
end;

function TCustomVirtualStringTree.ContentToText(Source: TVSTTextSourceType; const Separator: AnsiString): AnsiString;

var
  RenderColumns: Boolean;
  Tabs: AnsiString;
  GetNextNode: TGetNextNodeProc;
  Run, Save: PVirtualNode;
  Level, MaxLevel: Cardinal;
  Columns: TColumnsArray;
  LastColumn: TVirtualTreeColumn;
  Index,
  I: Integer;
  Text: AnsiString;
  Buffer: TBufferedAnsiString;

begin
  Columns := nil;
  Buffer := TBufferedAnsiString.Create;
  try
    RenderColumns := FHeader.UseColumns;
    if RenderColumns then
      Columns := FHeader.FColumns.GetVisibleColumns;

    GetRenderStartValues(Source, Run, GetNextNode);
    Save := Run;
    
    MaxLevel := 0;
    while Assigned(Run) do
    begin
      Level := GetNodeLevel(Run);
      If Level > MaxLevel then
        MaxLevel := Level;
      Run := GetNextNode(Run);
    end;

    Tabs := DupeString(Separator, MaxLevel);
    
    if RenderColumns then
    begin
      LastColumn := Columns[High(Columns)];
      for I := 0 to High(Columns) do
      begin
        Buffer.Add(Columns[I].Text);
        if Columns[I] <> LastColumn then
        begin
          if Columns[I].Index = Header.MainColumn then
          begin
            Buffer.Add(Tabs);
            Buffer.Add(Separator);
          end
          else
            Buffer.Add(Separator);
        end;
      end;
      Buffer.AddNewLine;
    end
    else
      LastColumn := nil;

    Run := Save;
    if RenderColumns then
    begin
      while Assigned(Run) do
      begin
        if (not CanExportNode(Run) or
           (Assigned(FOnBeforeNodeExport) and (not FOnBeforeNodeExport(Self, etText, Run)))) then
        begin
          Run := GetNextNode(Run);
          Continue;
        end;
        for I := 0 to High(Columns) do
        begin
          if coVisible in Columns[I].Options then
          begin
            Index := Columns[I].Index;
            
            Text := Self.Text[Run, Index];
            if Index = Header.MainColumn then
            begin
              Level := GetNodeLevel(Run);
              Buffer.Add(Copy(Tabs, 1, Integer(Level) * Length(Separator)));
              
              if (Pos(Separator, Text) > 0) or (Pos('"', Text) > 0) then
                Buffer.Add(AnsiQuotedStr(Text, '"'))
              else
                Buffer.Add(Text);
              Buffer.Add(Copy(Tabs, 1, Integer(MaxLevel - Level) * Length(Separator)));
            end
            else
              if (Pos(Separator, Text) > 0) or (Pos('"', Text) > 0) then
                Buffer.Add(AnsiQuotedStr(Text, '"'))
              else
                Buffer.Add(Text);

            if Columns[I] <> LastColumn then
              Buffer.Add(Separator);
          end;
        end;
        if Assigned(FOnAfterNodeExport) then
          FOnAfterNodeExport(Self, etText, Run);
        Run := GetNextNode(Run);
        Buffer.AddNewLine;
      end;
    end
    else
    begin
      while Assigned(Run) do
      begin
        if ((not CanExportNode(Run)) or
           (Assigned(FOnBeforeNodeExport) and (not FOnBeforeNodeExport(Self, etText, Run)))) then
        begin
          Run := GetNextNode(Run);
          Continue;
        end;
        
        Text := Self.Text[Run, NoColumn];
        Level := GetNodeLevel(Run);
        Buffer.Add(Copy(Tabs, 1, Integer(Level) * Length(Separator)));
        Buffer.Add(Text);
        Buffer.AddNewLine;

        if Assigned(FOnAfterNodeExport) then
          FonAfterNodeExport(Self, etText, Run);
        Run := GetNextNode(Run);
      end;
    end;

    Result := Buffer.AsString;
  finally
    Buffer.Free;
  end;
end;

function TCustomVirtualStringTree.ContentToUnicode(Source: TVSTTextSourceType; Separator: WideChar): UnicodeString;

begin
  Result := ContentToUnicode(Source, UnicodeString(Separator));
end;

function TCustomVirtualStringTree.ContentToUnicode(Source: TVSTTextSourceType; const Separator: UnicodeString): UnicodeString;

const
  WideCRLF: UnicodeString = #13#10;

var
  RenderColumns: Boolean;
  Tabs: UnicodeString;
  GetNextNode: TGetNextNodeProc;
  Run, Save: PVirtualNode;

  Columns: TColumnsArray;
  LastColumn: TVirtualTreeColumn;
  Level, MaxLevel: Cardinal;
  Index,
  I: Integer;
  Text: UnicodeString;
  Buffer: TWideBufferedString;

begin
  Columns := nil;

  Buffer := TWideBufferedString.Create;
  try
    RenderColumns := FHeader.UseColumns;
    if RenderColumns then
      Columns := FHeader.FColumns.GetVisibleColumns;

    GetRenderStartValues(Source, Run, GetNextNode);
    Save := Run;
    
    MaxLevel := 0;
    while Assigned(Run) do
    begin
      Level := GetNodeLevel(Run);
      If Level > MaxLevel then
        MaxLevel := Level;
      Run := GetNextNode(Run);
    end;

    Tabs := DupeString(Separator, MaxLevel);
    
    if RenderColumns then
    begin
      LastColumn := Columns[High(Columns)];
      for I := 0 to High(Columns) do
      begin
        Buffer.Add(Columns[I].Text);
        if Columns[I] <> LastColumn then
        begin
          if Columns[I].Index = Header.MainColumn then
          begin
            Buffer.Add(Tabs);
            Buffer.Add(Separator);
          end
          else
            Buffer.Add(Separator);
        end;
      end;
      Buffer.AddNewLine;
    end
    else
      LastColumn := nil;

    Run := Save;
    if RenderColumns then
    begin
      while Assigned(Run) do
      begin
        for I := 0 to High(Columns) do
        begin
          if coVisible in Columns[I].Options then
          begin
            Index := Columns[I].Index;
            Text := Self.Text[Run, Index];
            if Index = Header.MainColumn then
            begin
              Level := GetNodeLevel(Run);
              Buffer.Add(Copy(Tabs, 1, Integer(Level) * Length(Separator)));
              
              if Pos(Separator, Text) > 0 then
              begin
                Buffer.Add('"');
                Buffer.Add(Text);
                Buffer.Add('"');
              end
              else
                Buffer.Add(Text);
              Buffer.Add(Copy(Tabs, 1, Integer(MaxLevel - Level) * Length(Separator)));
            end
            else
              if Pos(Separator, Text) > 0 then
              begin
                Buffer.Add('"');
                Buffer.Add(Text);
                Buffer.Add('"');
              end
              else
                Buffer.Add(Text);

            if Columns[I] <> LastColumn then
              Buffer.Add(Separator);
          end;
        end;
        Run := GetNextNode(Run);
        Buffer.AddNewLine;
      end;
    end
    else
    begin
      while Assigned(Run) do
      begin
        Text := Self.Text[Run, NoColumn];
        Level := GetNodeLevel(Run);
        Buffer.Add(Copy(Tabs, 1, Integer(Level) * Length(Separator)));
        Buffer.Add(Text);
        Buffer.AddNewLine;

        Run := GetNextNode(Run);
      end;
    end;
    Result := Buffer.AsString;
  finally
    Buffer.Free;
  end;
end;

procedure TCustomVirtualStringTree.GetTextInfo(Node: PVirtualNode; Column: TColumnIndex; const AFont: TFont; var R: TRect;
  var Text: UnicodeString);

var
  NewHeight: Integer;
  TM: TTextMetric;

begin
  
  inherited GetTextInfo(Node, Column, AFont, R, Text);

  Canvas.Font := AFont;

  FFontChanged := False;
  RedirectFontChangeEvent(Canvas);
  DoPaintText(Node, Canvas, Column, ttNormal);
  if FFontChanged then
  begin
    AFont.Assign(Canvas.Font);
    GetTextMetrics(Canvas.Handle, TM);
    NewHeight := TM.tmHeight;
  end
  else 
    NewHeight := FTextHeight;
  RestoreFontChangeEvent(Canvas);
  
  Text := Self.Text[Node, Column];
  R := GetDisplayRect(Node, Column, True, not (vsMultiline in Node.States));
  if toShowHorzGridLines in TreeOptions.PaintOptions then
    Dec(R.Bottom);
  InflateRect(R, 0, -(R.Bottom - R.Top - NewHeight) div 2);
end;

function TCustomVirtualStringTree.InvalidateNode(Node: PVirtualNode): TRect;

var
  Data: PInteger;

begin
  Result := inherited InvalidateNode(Node);
  
  if Assigned(Node) then
  begin
    Data := InternalData(Node);
    if Assigned(Data) then
      Data^ := 0;
    
    Exclude(Node.States, vsHeightMeasured);
  end;
end;

function TCustomVirtualStringTree.Path(Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  Delimiter: WideChar): UnicodeString;

var
  S: UnicodeString;

begin
  if (Node = nil) or (Node = FRoot) then
    Result := Delimiter
  else
  begin
    Result := '';
    while Node <> FRoot do
    begin
      DoGetText(Node, Column, TextType, S);
      Result := S + Delimiter + Result;
      Node := Node.Parent;
    end;
  end;
end;

procedure TCustomVirtualStringTree.ReinitNode(Node: PVirtualNode; Recursive: Boolean);

var
  Data: PInteger;

begin
  inherited;
  
  if Assigned(Node) and (Node <> FRoot) then
  begin
    Data := InternalData(Node);
    if Assigned(Data) then
      Data^ := 0;
    
  end;
end;

function TVirtualStringTree.GetOptions: TStringTreeOptions;

begin
  Result := FOptions as TStringTreeOptions;
end;

procedure TVirtualStringTree.SetOptions(const Value: TStringTreeOptions);

begin
  FOptions.Assign(Value);
end;

function TVirtualStringTree.GetOptionsClass: TTreeOptionsClass;

begin
  Result := TStringTreeOptions;
end;

function TCustomVirtualDrawTree.DoGetCellContentMargin(Node: PVirtualNode; Column: TColumnIndex;
  CellContentMarginType: TVTCellContentMarginType = ccmtAllSides; Canvas: TCanvas = nil): TPoint;

begin
  Result := Point(0, 0);
  if Canvas = nil then
    Canvas := Self.Canvas;

  if Assigned(FOnGetCellContentMargin) then
    FOnGetCellContentMargin(Self, Canvas, Node, Column, CellContentMarginType, Result);
end;

function TCustomVirtualDrawTree.DoGetNodeWidth(Node: PVirtualNode; Column: TColumnIndex; Canvas: TCanvas = nil): Integer;

begin
  Result := 2 * FTextMargin;
  if Canvas = nil then
    Canvas := Self.Canvas;

  if Assigned(FOnGetNodeWidth) then
    FOnGetNodeWidth(Self, Canvas, Node, Column, Result);
end;

procedure TCustomVirtualDrawTree.DoPaintNode(var PaintInfo: TVTPaintInfo);

begin
  if Assigned(FOnDrawNode) then
    FOnDrawNode(Self, PaintInfo);
end;

function TCustomVirtualDrawTree.GetDefaultHintKind: TVTHintKind;

begin
  Result := vhkOwnerDraw;
end;

function TVirtualDrawTree.GetOptions: TVirtualTreeOptions;

begin
  Result := FOptions as TVirtualTreeOptions;
end;

procedure TVirtualDrawTree.SetOptions(const Value: TVirtualTreeOptions);

begin
  FOptions.Assign(Value);
end;

function TVirtualDrawTree.GetOptionsClass: TTreeOptionsClass;

begin
  Result := TVirtualTreeOptions;
end;

 {$if CompilerVersion >= 23 }

procedure TVclStyleScrollBarsHook.CalcScrollBarsRect;
var
  P: TPoint;
  BorderValue: TSize;
  BarInfo: TScrollBarInfo;
  I: Integer;

  procedure CalcVerticalRects;
  begin
    BarInfo.cbSize := SizeOf(BarInfo);
    GetScrollBarInfo(Handle, Integer(OBJID_VSCROLL), BarInfo);
    FVertScrollBarWindow.Visible := not(STATE_SYSTEM_INVISIBLE and BarInfo.rgstate[0] <> 0);
    FVertScrollBarWindow.Enabled := not(STATE_SYSTEM_UNAVAILABLE and BarInfo.rgstate[0] <> 0);
    if FVertScrollBarWindow.Visible then
    begin
      
      P := BarInfo.rcScrollBar.TopLeft;
      ScreenToClient(Handle, P);
      FVertScrollBarRect.TopLeft := P;
      P := BarInfo.rcScrollBar.BottomRight;
      ScreenToClient(Handle, P);
      FVertScrollBarRect.BottomRight := P;
      OffsetRect(FVertScrollBarRect, BorderValue.cx, BorderValue.cy);

      I := GetSystemMetrics(SM_CYVTHUMB);
      
      FVertScrollBarDownButtonRect := FVertScrollBarRect;
      FVertScrollBarDownButtonRect.Top := FVertScrollBarDownButtonRect.Bottom - I;
      
      FVertScrollBarUpButtonRect := FVertScrollBarRect;
      FVertScrollBarUpButtonRect.Bottom := FVertScrollBarUpButtonRect.Top + I;

      FVertScrollBarSliderTrackRect := FVertScrollBarRect;
      Inc(FVertScrollBarSliderTrackRect.Top, I);
      Dec(FVertScrollBarSliderTrackRect.Bottom, I);
    end;
  end;

  procedure CalcHorizontalRects;
  begin
    BarInfo.cbSize := SizeOf(BarInfo);
    GetScrollBarInfo(Handle, Integer(OBJID_HSCROLL), BarInfo);
    FHorzScrollBarWindow.Visible := not(STATE_SYSTEM_INVISIBLE and BarInfo.rgstate[0] <> 0);
    FHorzScrollBarWindow.Enabled := not(STATE_SYSTEM_UNAVAILABLE and BarInfo.rgstate[0] <> 0);
    if FHorzScrollBarWindow.Visible then
    begin
      
      P := BarInfo.rcScrollBar.TopLeft;
      ScreenToClient(Handle, P);
      FHorzScrollBarRect.TopLeft := P;
      P := BarInfo.rcScrollBar.BottomRight;
      ScreenToClient(Handle, P);
      FHorzScrollBarRect.BottomRight := P;
      OffsetRect(FHorzScrollBarRect, BorderValue.cx, BorderValue.cy);

      I := GetSystemMetrics(SM_CXHTHUMB);
      
      FHorzScrollBarDownButtonRect := FHorzScrollBarRect;
      FHorzScrollBarDownButtonRect.Left := FHorzScrollBarDownButtonRect.Right - I;
      
      FHorzScrollBarUpButtonRect := FHorzScrollBarRect;
      FHorzScrollBarUpButtonRect.Right := FHorzScrollBarUpButtonRect.Left + I;

      FHorzScrollBarSliderTrackRect := FHorzScrollBarRect;
      Inc(FHorzScrollBarSliderTrackRect.Left, I);
      Dec(FHorzScrollBarSliderTrackRect.Right, I);
    end;
  end;

begin
  BorderValue.cx := 0;
  BorderValue.cy := 0;
  if HasBorder then
    if HasClientEdge then
    begin
      BorderValue.cx := GetSystemMetrics(SM_CXEDGE);
      BorderValue.cy := GetSystemMetrics(SM_CYEDGE);
    end;
  CalcVerticalRects;
  CalcHorizontalRects;

end;

constructor TVclStyleScrollBarsHook.Create(AControl: TWinControl);
begin
  inherited;
  FVertScrollBarWindow := TVclStyleScrollBarWindow.CreateParented(GetParent(Control.Handle));
  FVertScrollBarWindow.ScrollBarWindowOwner := Self;
  FVertScrollBarWindow.ScrollBarVertical := True;

  FHorzScrollBarWindow := TVclStyleScrollBarWindow.CreateParented(GetParent(Control.Handle));
  FHorzScrollBarWindow.ScrollBarWindowOwner := Self;

  FVertScrollBarSliderState := tsThumbBtnVertNormal;
  FVertScrollBarUpButtonState := tsArrowBtnUpNormal;
  FVertScrollBarDownButtonState := tsArrowBtnDownNormal;
  FHorzScrollBarSliderState := tsThumbBtnHorzNormal;
  FHorzScrollBarUpButtonState := tsArrowBtnLeftNormal;
  FHorzScrollBarDownButtonState := tsArrowBtnRightNormal;
end;

destructor TVclStyleScrollBarsHook.Destroy;
begin
  FVertScrollBarWindow.ScrollBarWindowOwner := nil;
  FreeAndNil(FVertScrollBarWindow);
  FHorzScrollBarWindow.ScrollBarWindowOwner := nil;
  FreeAndNil(FHorzScrollBarWindow);
  inherited;
end;

procedure TVclStyleScrollBarsHook.DrawHorzScrollBar(DC: HDC);
var
  B: TBitmap;
  Details: TThemedElementDetails;
  R: TRect;
begin
  if ((Handle = 0) or (DC = 0)) then
    Exit;
  if FHorzScrollBarWindow.Visible and StyleServices.Available then
  begin
    B := TBitmap.Create;
    try
      B.Width := FHorzScrollBarRect.Width;
      B.Height := FHorzScrollBarRect.Height;
      MoveWindowOrg(B.Canvas.Handle, -FHorzScrollBarRect.Left, -FHorzScrollBarRect.Top);
      R := FHorzScrollBarRect;
      R.Left := FHorzScrollBarUpButtonRect.Right;
      R.Right := FHorzScrollBarDownButtonRect.Left;

      Details := StyleServices.GetElementDetails(tsUpperTrackHorzNormal);
      StyleServices.DrawElement(B.Canvas.Handle, Details, R);

      if FHorzScrollBarWindow.Enabled then
        Details := StyleServices.GetElementDetails(FHorzScrollBarSliderState);
      StyleServices.DrawElement(B.Canvas.Handle, Details, GetHorzScrollBarSliderRect);

      if FHorzScrollBarWindow.Enabled then
        Details := StyleServices.GetElementDetails(FHorzScrollBarUpButtonState)
      else
        Details := StyleServices.GetElementDetails(tsArrowBtnLeftDisabled);
      StyleServices.DrawElement(B.Canvas.Handle, Details, FHorzScrollBarUpButtonRect);

      if FHorzScrollBarWindow.Enabled then
        Details := StyleServices.GetElementDetails(FHorzScrollBarDownButtonState)
      else
        Details := StyleServices.GetElementDetails(tsArrowBtnRightDisabled);
      StyleServices.DrawElement(B.Canvas.Handle, Details, FHorzScrollBarDownButtonRect);

      MoveWindowOrg(B.Canvas.Handle, FHorzScrollBarRect.Left, FHorzScrollBarRect.Top);
      with FHorzScrollBarRect do
        BitBlt(DC, Left, Top, B.Width, B.Height, B.Canvas.Handle, 0, 0, SRCCOPY);
    finally
      B.Free;
    end;
  end;
end;

procedure TVclStyleScrollBarsHook.DrawVertScrollBar(DC: HDC);
var
  B: TBitmap;
  Details: TThemedElementDetails;
  R: TRect;
begin
  if ((Handle = 0) or (DC = 0)) then
    Exit;
  if FVertScrollBarWindow.Visible and StyleServices.Available then
  begin
    B := TBitmap.Create;
    try
      B.Width := FVertScrollBarRect.Width;
      B.Height := FVertScrollBarWindow.Height;
      MoveWindowOrg(B.Canvas.Handle, -FVertScrollBarRect.Left, -FVertScrollBarRect.Top);
      R := FVertScrollBarRect;
      R.Bottom := B.Height + FVertScrollBarRect.Top;
      Details := StyleServices.GetElementDetails(tsUpperTrackVertNormal);
      StyleServices.DrawElement(B.Canvas.Handle, Details, R);
      R.Top := FVertScrollBarUpButtonRect.Bottom;
      R.Bottom := FVertScrollBarDownButtonRect.Top;

      Details := StyleServices.GetElementDetails(tsUpperTrackVertNormal);
      StyleServices.DrawElement(B.Canvas.Handle, Details, R);

      if FVertScrollBarWindow.Enabled then
        Details := StyleServices.GetElementDetails(FVertScrollBarSliderState);
      StyleServices.DrawElement(B.Canvas.Handle, Details, GetVertScrollBarSliderRect);

      if FVertScrollBarWindow.Enabled then
        Details := StyleServices.GetElementDetails(FVertScrollBarUpButtonState)
      else
        Details := StyleServices.GetElementDetails(tsArrowBtnUpDisabled);
      StyleServices.DrawElement(B.Canvas.Handle, Details, FVertScrollBarUpButtonRect);

      if FVertScrollBarWindow.Enabled then
        Details := StyleServices.GetElementDetails(FVertScrollBarDownButtonState)
      else
        Details := StyleServices.GetElementDetails(tsArrowBtnDownDisabled);
      StyleServices.DrawElement(B.Canvas.Handle, Details, FVertScrollBarDownButtonRect);

      MoveWindowOrg(B.Canvas.Handle, FVertScrollBarRect.Left, FVertScrollBarRect.Top);
      with FVertScrollBarRect do
        BitBlt(DC, Left, Top, B.Width, B.Height, B.Canvas.Handle, 0, 0, SRCCOPY);
    finally
      B.Free;
    end;
  end;
end;

function TVclStyleScrollBarsHook.GetHorzScrollBarSliderRect: TRect;
var
  P: TPoint;
  BarInfo: TScrollBarInfo;
begin
  if FHorzScrollBarWindow.Visible and FHorzScrollBarWindow.Enabled then
  begin
    BarInfo.cbSize := SizeOf(BarInfo);
    GetScrollBarInfo(Handle, Integer(OBJID_HSCROLL), BarInfo);
    P := BarInfo.rcScrollBar.TopLeft;
    ScreenToClient(Handle, P);
    Result.TopLeft := P;
    P := BarInfo.rcScrollBar.BottomRight;
    ScreenToClient(Handle, P);
    Result.BottomRight := P;
    Result.Left := BarInfo.xyThumbTop;
    Result.Right := BarInfo.xyThumbBottom;
    if HasBorder then
      if HasClientEdge then
        OffsetRect(Result, 2, 2)
      else
        OffsetRect(Result, 1, 1);
  end;
end;

function TVclStyleScrollBarsHook.GetVertScrollBarSliderRect: TRect;
var
  P: TPoint;
  BarInfo: TScrollBarInfo;
begin
  if FVertScrollBarWindow.Visible and FVertScrollBarWindow.Enabled then
  begin
    BarInfo.cbSize := SizeOf(BarInfo);
    GetScrollBarInfo(Handle, Integer(OBJID_VSCROLL), BarInfo);
    P := BarInfo.rcScrollBar.TopLeft;
    ScreenToClient(Handle, P);
    Result.TopLeft := P;
    P := BarInfo.rcScrollBar.BottomRight;
    ScreenToClient(Handle, P);
    Result.BottomRight := P;
    Result.Top := BarInfo.xyThumbTop;
    Result.Bottom := BarInfo.xyThumbBottom;
    if HasBorder then
      if HasClientEdge then
        OffsetRect(Result, 2, 2)
      else
        OffsetRect(Result, 1, 1);
  end;
end;

procedure TVclStyleScrollBarsHook.MouseLeave;
begin
   inherited;
  if FVertScrollBarSliderState = tsThumbBtnVertHot then
    FVertScrollBarSliderState := tsThumbBtnVertNormal;

  if FHorzScrollBarSliderState = tsThumbBtnHorzHot then
    FHorzScrollBarSliderState := tsThumbBtnHorzNormal;

  if FVertScrollBarUpButtonState = tsArrowBtnUpHot then
    FVertScrollBarUpButtonState := tsArrowBtnUpNormal;

  if FVertScrollBarDownButtonState = tsArrowBtnDownHot then
    FVertScrollBarDownButtonState := tsArrowBtnDownNormal;

  if FHorzScrollBarUpButtonState = tsArrowBtnLeftHot then
    FHorzScrollBarUpButtonState := tsArrowBtnLeftNormal;

  if FHorzScrollBarDownButtonState = tsArrowBtnRightHot then
    FHorzScrollBarDownButtonState := tsArrowBtnRightNormal;

  PaintScrollBars;
end;

procedure TVclStyleScrollBarsHook.PaintScrollBars;
begin
  FVertScrollBarWindow.Repaint;
  FHorzScrollBarWindow.Repaint;
end;

function TVclStyleScrollBarsHook.PointInTreeHeader(const P: TPoint): Boolean;
begin
  Result := TBaseVirtualTree(Control).FHeader.InHeader(P);
end;

procedure TVclStyleScrollBarsHook.UpdateScrollBarWindow;
var
  R: TRect;
  Owner: TBaseVirtualTree;
  HeaderHeight: Integer;
  BorderWidth: Integer;
begin
  Owner := TBaseVirtualTree(Control);
  if (hoVisible in Owner.Header.Options) then
    HeaderHeight := Owner.FHeader.Height
  else
    HeaderHeight := 0;
  BorderWidth := 0;
  
  if FVertScrollBarWindow.Visible then
  begin
    R := FVertScrollBarRect;
    if Control.BidiMode = bdRightToLeft then
    begin
      OffsetRect(R, -R.Left, 0);
      if HasBorder then
        OffsetRect(R, GetSystemMetrics(SM_CXEDGE), 0);
    end;
    if HasBorder then
      BorderWidth := GetSystemMetrics(SM_CYEDGE) * 2;
    ShowWindow(FVertScrollBarWindow.Handle, SW_SHOW);
    SetWindowPos(FVertScrollBarWindow.Handle, HWND_TOP, Control.Left + R.Left, Control.Top + R.Top + HeaderHeight, R.Right - R.Left,
      Control.Height - HeaderHeight  - BorderWidth, SWP_SHOWWINDOW);
  end
  else
    ShowWindow(FVertScrollBarWindow.Handle, SW_HIDE);
  
  if FHorzScrollBarWindow.Visible then
  begin
    R := FHorzScrollBarRect;
    if Control.BidiMode = bdRightToLeft then
      OffsetRect(R, FVertScrollBarRect.Width, 0);
    ShowWindow(FHorzScrollBarWindow.Handle, SW_SHOW);
    SetWindowPos(FHorzScrollBarWindow.Handle, HWND_TOP, Control.Left + R.Left, Control.Top + R.Top + HeaderHeight, R.Right - R.Left,
      R.Bottom - R.Top, SWP_SHOWWINDOW);
  end
  else
    ShowWindow(FHorzScrollBarWindow.Handle, SW_HIDE);
end;

procedure TVclStyleScrollBarsHook.WMCaptureChanged(var Msg: TMessage);
begin
   if FVertScrollBarWindow.Visible and FVertScrollBarWindow.Enabled then
  begin
    if FVertScrollBarUpButtonState = tsArrowBtnUpPressed then
    begin
      FVertScrollBarUpButtonState := tsArrowBtnUpNormal;
      PaintScrollBars;
    end;

    if FVertScrollBarDownButtonState = tsArrowBtnDownPressed then
    begin
      FVertScrollBarDownButtonState := tsArrowBtnDownNormal;
      PaintScrollBars;
    end;
  end;

  if FHorzScrollBarWindow.Visible and FHorzScrollBarWindow.Enabled then
  begin
    if FHorzScrollBarUpButtonState = tsArrowBtnLeftPressed then
    begin
      FHorzScrollBarUpButtonState := tsArrowBtnLeftNormal;
      PaintScrollBars;
    end;

    if FHorzScrollBarDownButtonState = tsArrowBtnRightPressed then
    begin
      FHorzScrollBarDownButtonState := tsArrowBtnRightNormal;
      PaintScrollBars;
    end;
  end;

  CallDefaultProc(TMessage(Msg));
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMHScroll(var Msg: TMessage);
begin
  CallDefaultProc(TMessage(Msg));
  PaintScrollBars;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMKeyDown(var Msg: TMessage);
begin
  CallDefaultProc(TMessage(Msg));
  PaintScrollBars;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMKeyUp(var Msg: TMessage);
begin
  CallDefaultProc(TMessage(Msg));
  PaintScrollBars;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMLButtonDown(var Msg: TWMMouse);
begin
  CallDefaultProc(TMessage(Msg));
  PaintScrollBars;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMLButtonUp(var Msg: TWMMouse);
var
  P: TPoint;
begin
  P := Point(Msg.XPos, Msg.YPos);
  ScreenToClient(Handle, P);
  if not PointInTreeHeader(P) then
  begin
    if FVertScrollBarWindow.Visible then
    begin
      if FVertScrollBarSliderState = tsThumbBtnVertPressed then
      begin
        PostMessage(Handle, WM_VSCROLL, Integer(SmallPoint(SB_ENDSCROLL, 0)), 0);
        FLeftMouseButtonDown := False;
        FVertScrollBarSliderState := tsThumbBtnVertNormal;
        PaintScrollBars;
        Handled := True;
        ReleaseCapture;
        Exit;
      end;

      if FVertScrollBarUpButtonState = tsArrowBtnUpPressed then
        FVertScrollBarUpButtonState := tsArrowBtnUpNormal;

      if FVertScrollBarDownButtonState = tsArrowBtnDownPressed then
        FVertScrollBarDownButtonState := tsArrowBtnDownNormal;
    end;

    if FHorzScrollBarWindow.Visible then
    begin
      if FHorzScrollBarSliderState = tsThumbBtnHorzPressed then
      begin
        PostMessage(Handle, WM_HSCROLL, Integer(SmallPoint(SB_ENDSCROLL, 0)), 0);
        FLeftMouseButtonDown := False;
        FHorzScrollBarSliderState := tsThumbBtnHorzNormal;
        PaintScrollBars;
        Handled := True;
        ReleaseCapture;
        Exit;
      end;

      if FHorzScrollBarUpButtonState = tsArrowBtnLeftPressed then
        FHorzScrollBarUpButtonState := tsArrowBtnLeftNormal;

      if FHorzScrollBarDownButtonState = tsArrowBtnRightPressed then
        FHorzScrollBarDownButtonState := tsArrowBtnRightNormal;
    end;
    PaintScrollBars;
  end;
  FLeftMouseButtonDown := False;
end;

procedure TVclStyleScrollBarsHook.WMMouseMove(var Msg: TWMMouse);
var
  SF: TScrollInfo;
begin
  inherited;
  if FVertScrollBarSliderState = tsThumbBtnVertPressed then
  begin
    SF.fMask := SIF_ALL;
    SF.cbSize := SizeOf(SF);
    GetScrollInfo(Handle, SB_VERT, SF);
    if SF.nPos <> Round(FScrollPos) then
      FScrollPos := SF.nPos;

    FScrollPos := FScrollPos + (SF.nMax - SF.nMin) * ((Mouse.CursorPos.Y - FPrevScrollPos) / FVertScrollBarSliderTrackRect.Height);
    if FScrollPos < SF.nMin then
      FScrollPos := SF.nMin;
    if FScrollPos > SF.nMax then
      FScrollPos := SF.nMax;
    if SF.nPage <> 0 then
      if Round(FScrollPos) > SF.nMax - Integer(SF.nPage) + 1 then
        FScrollPos := SF.nMax - Integer(SF.nPage) + 1;
    FPrevScrollPos := Mouse.CursorPos.Y;
    SF.nPos := Round(FScrollPos);

    SetScrollInfo(Handle, SB_VERT, SF, False);
    PostMessage(Handle, WM_VSCROLL, Integer(SmallPoint(SB_THUMBPOSITION, Round(FScrollPos))), 0);

    PaintScrollBars;
    Handled := True;
    Exit;
  end;

  if FHorzScrollBarSliderState = tsThumbBtnHorzPressed then
  begin
    SF.fMask := SIF_ALL;
    SF.cbSize := SizeOf(SF);
    GetScrollInfo(Handle, SB_HORZ, SF);
    if SF.nPos <> Round(FScrollPos) then
      FScrollPos := SF.nPos;

    FScrollPos := FScrollPos + (SF.nMax - SF.nMin) * ((Mouse.CursorPos.X - FPrevScrollPos) / FHorzScrollBarSliderTrackRect.Width);
    if FScrollPos < SF.nMin then
      FScrollPos := SF.nMin;
    if FScrollPos > SF.nMax then
      FScrollPos := SF.nMax;
    if SF.nPage <> 0 then
      if Round(FScrollPos) > SF.nMax - Integer(SF.nPage) + 1 then
        FScrollPos := SF.nMax - Integer(SF.nPage) + 1;
    FPrevScrollPos := Mouse.CursorPos.X;
    SF.nPos := Round(FScrollPos);

    SetScrollInfo(Handle, SB_HORZ, SF, False);
    PostMessage(Handle, WM_HSCROLL, Integer(SmallPoint(SB_THUMBPOSITION, Round(FScrollPos))), 0);

    PaintScrollBars;
    Handled := True;
    Exit;
  end;

  if (FHorzScrollBarSliderState <> tsThumbBtnHorzPressed) and (FHorzScrollBarSliderState = tsThumbBtnHorzHot) then
  begin
    FHorzScrollBarSliderState := tsThumbBtnHorzNormal;
    PaintScrollBars;
  end;

  if (FVertScrollBarSliderState <> tsThumbBtnVertPressed) and (FVertScrollBarSliderState = tsThumbBtnVertHot) then
  begin
    FVertScrollBarSliderState := tsThumbBtnVertNormal;
    PaintScrollBars;
  end;

  if (FHorzScrollBarUpButtonState <> tsArrowBtnLeftPressed) and (FHorzScrollBarUpButtonState = tsArrowBtnLeftHot) then
  begin
    FHorzScrollBarUpButtonState := tsArrowBtnLeftNormal;
    PaintScrollBars;
  end;

  if (FHorzScrollBarDownButtonState <> tsArrowBtnRightPressed) and (FHorzScrollBarDownButtonState = tsArrowBtnRightHot) then
  begin
    FHorzScrollBarDownButtonState := tsArrowBtnRightNormal;
    PaintScrollBars;
  end;

  if (FVertScrollBarUpButtonState <> tsArrowBtnUpPressed) and (FVertScrollBarUpButtonState = tsArrowBtnUpHot) then
  begin
    FVertScrollBarUpButtonState := tsArrowBtnUpNormal;
    PaintScrollBars;
  end;

  if (FVertScrollBarDownButtonState <> tsArrowBtnDownPressed) and (FVertScrollBarDownButtonState = tsArrowBtnDownHot) then
  begin
    FVertScrollBarDownButtonState := tsArrowBtnDownNormal;
    PaintScrollBars;
  end;

  CallDefaultProc(TMessage(Msg));
  if FLeftMouseButtonDown then
    PaintScrollBars;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMMouseWheel(var Msg: TMessage);
begin
   CallDefaultProc(TMessage(Msg));
  PaintScrollBars;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMNCLButtonDblClk(var Msg: TWMMouse);
begin
  WMNCLButtonDown(Msg);
end;

procedure TVclStyleScrollBarsHook.WMNCLButtonDown(var Msg: TWMMouse);
var
  P: TPoint;
  SF: TScrollInfo;
begin
  P := Point(Msg.XPos, Msg.YPos);
  ScreenToClient(Handle, P);

  if HasBorder then
    if HasClientEdge then
    begin
      P.X := P.X + 2;
      P.Y := P.Y + 2;
    end
    else
    begin
      P.X := P.X + 1;
      P.Y := P.Y + 1;
    end;

  if not PointInTreeHeader(P) then
  begin
    if FVertScrollBarWindow.Visible then
    begin
      if PtInRect(GetVertScrollBarSliderRect, P) then
      begin
        FLeftMouseButtonDown := True;
        SF.fMask := SIF_ALL;
        SF.cbSize := SizeOf(SF);
        GetScrollInfo(Handle, SB_VERT, SF);
        
        FScrollPos := SF.nPos;
        FPrevScrollPos := Mouse.CursorPos.Y;
        FVertScrollBarSliderState := tsThumbBtnVertPressed;
        PaintScrollBars;
        SetCapture(Handle);
        Handled := True;
        Exit;
      end;

      if FVertScrollBarWindow.Enabled then
      begin
        if PtInRect(FVertScrollBarDownButtonRect, P) then
          FVertScrollBarDownButtonState := tsArrowBtnDownPressed;
        if PtInRect(FVertScrollBarUpButtonRect, P) then
          FVertScrollBarUpButtonState := tsArrowBtnUpPressed;
      end;
    end;

    if FHorzScrollBarWindow.Visible then
    begin
      if PtInRect(GetHorzScrollBarSliderRect, P) then
      begin
        FLeftMouseButtonDown := True;
        SF.fMask := SIF_ALL;
        SF.cbSize := SizeOf(SF);
        GetScrollInfo(Handle, SB_HORZ, SF);
        
        FScrollPos := SF.nPos;
        FPrevScrollPos := Mouse.CursorPos.X;
        FHorzScrollBarSliderState := tsThumbBtnHorzPressed;
        PaintScrollBars;
        SetCapture(Handle);
        Handled := True;
        Exit;
      end;

      if FHorzScrollBarWindow.Enabled then
      begin
        if PtInRect(FHorzScrollBarDownButtonRect, P) then
          FHorzScrollBarDownButtonState := tsArrowBtnRightPressed;
        if PtInRect(FHorzScrollBarUpButtonRect, P) then
          FHorzScrollBarUpButtonState := tsArrowBtnLeftPressed;
      end;
    end;
    FLeftMouseButtonDown := True;
    PaintScrollBars;
  end;
end;

procedure TVclStyleScrollBarsHook.WMNCLButtonUp(var Msg: TWMMouse);
var
  P: TPoint;
  B: Boolean;
begin
  P := Point(Msg.XPos, Msg.YPos);
  ScreenToClient(Handle, P);

  if HasBorder then
    if HasClientEdge then
    begin
      P.X := P.X + 2;
      P.Y := P.Y + 2;
    end
    else
    begin
      P.X := P.X + 1;
      P.Y := P.Y + 1;
    end;

  B := PointInTreeHeader(P);

  if not B then
  begin
    if FVertScrollBarWindow.Visible then
      if FVertScrollBarWindow.Enabled then
      begin
        if FVertScrollBarSliderState = tsThumbBtnVertPressed then
        begin
          FLeftMouseButtonDown := False;
          FVertScrollBarSliderState := tsThumbBtnVertNormal;
          PaintScrollBars;
          Handled := True;
          Exit;
        end;

        if PtInRect(FVertScrollBarDownButtonRect, P) then
          FVertScrollBarDownButtonState := tsArrowBtnDownHot
        else
          FVertScrollBarDownButtonState := tsArrowBtnDownNormal;

        if PtInRect(FVertScrollBarUpButtonRect, P) then
          FVertScrollBarUpButtonState := tsArrowBtnUpHot
        else
          FVertScrollBarUpButtonState := tsArrowBtnUpNormal;
      end;

    if FHorzScrollBarWindow.Visible then
      if FHorzScrollBarWindow.Enabled then
      begin
        if FHorzScrollBarSliderState = tsThumbBtnHorzPressed then
        begin
          FLeftMouseButtonDown := False;
          FHorzScrollBarSliderState := tsThumbBtnHorzNormal;
          PaintScrollBars;
          Handled := True;
          Exit;
        end;

        if PtInRect(FHorzScrollBarDownButtonRect, P) then
          FHorzScrollBarDownButtonState := tsArrowBtnRightHot
        else
          FHorzScrollBarDownButtonState := tsArrowBtnRightNormal;

        if PtInRect(FHorzScrollBarUpButtonRect, P) then
          FHorzScrollBarUpButtonState := tsArrowBtnLeftHot
        else
          FHorzScrollBarUpButtonState := tsArrowBtnLeftNormal;
      end;

  end;
  CallDefaultProc(TMessage(Msg));
  if not B and (FHorzScrollBarWindow.Visible) or (FVertScrollBarWindow.Visible) then
    PaintScrollBars;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMNCMouseMove(var Msg: TWMMouse);
var
  P: TPoint;
  MustUpdateScroll: Boolean;
  B: Boolean;
begin
  inherited;
  P := Point(Msg.XPos, Msg.YPos);
  ScreenToClient(Handle, P);

  if PointInTreeHeader(P) then
  begin
    CallDefaultProc(TMessage(Msg));
    PaintScrollBars;
    Handled := True;
    Exit;
  end;

  if HasBorder then
    if HasClientEdge then
    begin
      P.X := P.X + 2;
      P.Y := P.Y + 2;
    end
    else
    begin
      P.X := P.X + 1;
      P.Y := P.Y + 1;
    end;

  MustUpdateScroll := False;
  if FVertScrollBarWindow.Enabled then
  begin
    B := PtInRect(GetVertScrollBarSliderRect, P);
    if B and (FVertScrollBarSliderState = tsThumbBtnVertNormal) then
    begin
      FVertScrollBarSliderState := tsThumbBtnVertHot;
      MustUpdateScroll := True;
    end
    else if not B and (FVertScrollBarSliderState = tsThumbBtnVertHot) then
    begin
      FVertScrollBarSliderState := tsThumbBtnVertNormal;
      MustUpdateScroll := True;
    end;

    B := PtInRect(FVertScrollBarDownButtonRect, P);
    if B and (FVertScrollBarDownButtonState = tsArrowBtnDownNormal) then
    begin
      FVertScrollBarDownButtonState := tsArrowBtnDownHot;
      MustUpdateScroll := True;
    end
    else if not B and (FVertScrollBarDownButtonState = tsArrowBtnDownHot) then
    begin
      FVertScrollBarDownButtonState := tsArrowBtnDownNormal;
      MustUpdateScroll := True;
    end;
    B := PtInRect(FVertScrollBarUpButtonRect, P);
    if B and (FVertScrollBarUpButtonState = tsArrowBtnUpNormal) then
    begin
      FVertScrollBarUpButtonState := tsArrowBtnUpHot;
      MustUpdateScroll := True;
    end
    else if not B and (FVertScrollBarUpButtonState = tsArrowBtnUpHot) then
    begin
      FVertScrollBarUpButtonState := tsArrowBtnUpNormal;
      MustUpdateScroll := True;
    end;
  end;

  if FHorzScrollBarWindow.Enabled then
  begin
    B := PtInRect(GetHorzScrollBarSliderRect, P);
    if B and (FHorzScrollBarSliderState = tsThumbBtnHorzNormal) then
    begin
      FHorzScrollBarSliderState := tsThumbBtnHorzHot;
      MustUpdateScroll := True;
    end
    else if not B and (FHorzScrollBarSliderState = tsThumbBtnHorzHot) then
    begin
      FHorzScrollBarSliderState := tsThumbBtnHorzNormal;
      MustUpdateScroll := True;
    end;

    B := PtInRect(FHorzScrollBarDownButtonRect, P);
    if B and (FHorzScrollBarDownButtonState = tsArrowBtnRightNormal) then
    begin
      FHorzScrollBarDownButtonState := tsArrowBtnRightHot;
      MustUpdateScroll := True;
    end
    else if not B and (FHorzScrollBarDownButtonState = tsArrowBtnRightHot) then
    begin
      FHorzScrollBarDownButtonState := tsArrowBtnRightNormal;
      MustUpdateScroll := True;
    end;

    B := PtInRect(FHorzScrollBarUpButtonRect, P);
    if B and (FHorzScrollBarUpButtonState = tsArrowBtnLeftNormal) then
    begin
      FHorzScrollBarUpButtonState := tsArrowBtnLeftHot;
      MustUpdateScroll := True;
    end
    else if not B and (FHorzScrollBarUpButtonState = tsArrowBtnLeftHot) then
    begin
      FHorzScrollBarUpButtonState := tsArrowBtnLeftNormal;
      MustUpdateScroll := True;
    end;
  end;

  if MustUpdateScroll then
    PaintScrollBars;
end;

procedure TVclStyleScrollBarsHook.WMNCPaint(var Msg: TMessage);
begin
  CalcScrollBarsRect;
  UpdateScrollBarWindow;

end;

procedure TVclStyleScrollBarsHook.WMSize(var Msg: TMessage);
begin
  CallDefaultProc(TMessage(Msg));
  CalcScrollBarsRect;
  UpdateScrollBarWindow;
  PaintScrollBars;
  Handled := True;
end;

procedure TVclStyleScrollBarsHook.WMVScroll(var Msg: TMessage);
begin
  CallDefaultProc(TMessage(Msg));
  PaintScrollBars;
  Handled := True;
end;

constructor TVclStyleScrollBarsHook.TVclStyleScrollBarWindow.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOverrideStylePaint];
  FScrollBarWindowOwner := nil;
  FScrollBarVertical := False;
  FScrollBarVisible := False;
  FScrollBarEnabled := False;
end;

procedure TVclStyleScrollBarsHook.TVclStyleScrollBarWindow.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := Params.Style or WS_CHILDWINDOW or WS_CLIPCHILDREN or WS_CLIPSIBLINGS;
  Params.ExStyle := Params.ExStyle or WS_EX_NOPARENTNOTIFY;
end;

procedure TVclStyleScrollBarsHook.TVclStyleScrollBarWindow.WMEraseBkgnd(var Msg: TMessage);
begin
   Msg.Result := 1;
end;

procedure TVclStyleScrollBarsHook.TVclStyleScrollBarWindow.WMNCHitTest(var Msg: TWMNCHitTest);
begin
   Msg.Result := HTTRANSPARENT;
end;

procedure TVclStyleScrollBarsHook.TVclStyleScrollBarWindow.WMPaint(var Msg: TWMPaint);
var
  PS: TPaintStruct;
  DC: HDC;
begin
  BeginPaint(Handle, PS);
  try
    if FScrollBarWindowOwner <> nil then
    begin
      DC := GetWindowDC(Handle);
      try
        if FScrollBarVertical then
        begin
          MoveWindowOrg(DC, -FScrollBarWindowOwner.FVertScrollBarRect.Left, -FScrollBarWindowOwner.FVertScrollBarRect.Top);
          FScrollBarWindowOwner.DrawVertScrollBar(DC);
        end
        else
        begin
          MoveWindowOrg(DC, -FScrollBarWindowOwner.FHorzScrollBarRect.Left, -FScrollBarWindowOwner.FHorzScrollBarRect.Top);
          FScrollBarWindowOwner.DrawHorzScrollBar(DC);
        end;
      finally
        ReleaseDC(Handle, DC);
      end;
    end;
  finally
    EndPaint(Handle, PS);
  end;
end;
{$ifend}

initialization
  
  Initialized := False;
  NeedToUnitialize := False;
  
  Watcher := TCriticalSection.Create;

finalization
  if Initialized then
    FinalizeGlobalStructures;

  InternalClipboardFormats.Free;
  InternalClipboardFormats := nil;
  Watcher.Free;
  Watcher := nil;

end.
 