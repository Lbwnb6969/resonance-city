// Exact excerpts from libfmod 2.222.6 src/ffi.rs

pub const FMOD_VERSION: c_uint = 0x00020222;
pub const FMOD_STUDIO_LOADING_STATE_UNLOADING: FMOD_STUDIO_LOADING_STATE = 0;
pub const FMOD_STUDIO_LOADING_STATE_UNLOADED: FMOD_STUDIO_LOADING_STATE = 1;
pub const FMOD_STUDIO_LOADING_STATE_LOADING: FMOD_STUDIO_LOADING_STATE = 2;
pub const FMOD_STUDIO_LOADING_STATE_LOADED: FMOD_STUDIO_LOADING_STATE = 3;
pub const FMOD_STUDIO_LOADING_STATE_ERROR: FMOD_STUDIO_LOADING_STATE = 4;
pub const FMOD_STUDIO_LOADING_STATE_FORCEINT: FMOD_STUDIO_LOADING_STATE = 65536;
pub const FMOD_STUDIO_PARAMETER_GAME_CONTROLLED: FMOD_STUDIO_PARAMETER_TYPE = 0;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC_DISTANCE: FMOD_STUDIO_PARAMETER_TYPE = 1;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC_EVENT_CONE_ANGLE: FMOD_STUDIO_PARAMETER_TYPE = 2;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC_EVENT_ORIENTATION: FMOD_STUDIO_PARAMETER_TYPE = 3;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC_DIRECTION: FMOD_STUDIO_PARAMETER_TYPE = 4;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC_ELEVATION: FMOD_STUDIO_PARAMETER_TYPE = 5;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC_LISTENER_ORIENTATION: FMOD_STUDIO_PARAMETER_TYPE = 6;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC_SPEED: FMOD_STUDIO_PARAMETER_TYPE = 7;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC_SPEED_ABSOLUTE: FMOD_STUDIO_PARAMETER_TYPE = 8;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC_DISTANCE_NORMALIZED: FMOD_STUDIO_PARAMETER_TYPE = 9;
pub const FMOD_STUDIO_PARAMETER_MAX: FMOD_STUDIO_PARAMETER_TYPE = 10;
pub const FMOD_STUDIO_PARAMETER_FORCEINT: FMOD_STUDIO_PARAMETER_TYPE = 65536;
pub const FMOD_ERR_TRUNCATED: FMOD_RESULT = 65;
pub const FMOD_ERR_EVENT_NOTFOUND: FMOD_RESULT = 74;
pub const FMOD_OUTPUTTYPE_NOSOUND_NRT: FMOD_OUTPUTTYPE = 4;
pub const FMOD_STUDIO_INIT_SYNCHRONOUS_UPDATE: FMOD_STUDIO_INITFLAGS = 0x00000004;
pub const FMOD_STUDIO_PARAMETER_READONLY: FMOD_STUDIO_PARAMETER_FLAGS = 0x00000001;
pub const FMOD_STUDIO_PARAMETER_AUTOMATIC: FMOD_STUDIO_PARAMETER_FLAGS = 0x00000002;
pub const FMOD_STUDIO_PARAMETER_GLOBAL: FMOD_STUDIO_PARAMETER_FLAGS = 0x00000004;
pub const FMOD_STUDIO_PARAMETER_DISCRETE: FMOD_STUDIO_PARAMETER_FLAGS = 0x00000008;
pub const FMOD_STUDIO_PARAMETER_LABELED: FMOD_STUDIO_PARAMETER_FLAGS = 0x00000010;

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct FMOD_GUID {
    pub Data1: c_uint,
    pub Data2: c_ushort,
    pub Data3: c_ushort,
    pub Data4: [c_uchar; 8 as usize],
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct FMOD_STUDIO_PARAMETER_ID {
    pub data1: c_uint,
    pub data2: c_uint,
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct FMOD_STUDIO_PARAMETER_DESCRIPTION {
    pub name: *const c_char,
    pub id: FMOD_STUDIO_PARAMETER_ID,
    pub minimum: c_float,
    pub maximum: c_float,
    pub defaultvalue: c_float,
    pub type_: FMOD_STUDIO_PARAMETER_TYPE,
    pub flags: FMOD_STUDIO_PARAMETER_FLAGS,
    pub guid: FMOD_GUID,
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct FMOD_STUDIO_USER_PROPERTY {
    pub name: *const c_char,
    pub type_: FMOD_STUDIO_USER_PROPERTY_TYPE,
    pub union: FMOD_STUDIO_USER_PROPERTY_UNION,
}

#[repr(C)]
#[derive(Copy, Clone)]
pub union FMOD_STUDIO_USER_PROPERTY_UNION {
    pub intvalue: c_int,
    pub boolvalue: FMOD_BOOL,
    pub floatvalue: c_float,
    pub stringvalue: *const c_char,
}

pub fn FMOD_Studio_System_Create(
        system: *mut *mut FMOD_STUDIO_SYSTEM,
        headerversion: c_uint,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_Initialize(
        system: *mut FMOD_STUDIO_SYSTEM,
        maxchannels: c_int,
        studioflags: FMOD_STUDIO_INITFLAGS,
        flags: FMOD_INITFLAGS,
        extradriverdata: *mut c_void,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_Release(system: *mut FMOD_STUDIO_SYSTEM) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetCoreSystem(
        system: *mut FMOD_STUDIO_SYSTEM,
        coresystem: *mut *mut FMOD_SYSTEM,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetEvent(
        system: *mut FMOD_STUDIO_SYSTEM,
        pathOrID: *const c_char,
        event: *mut *mut FMOD_STUDIO_EVENTDESCRIPTION,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetBank(
        system: *mut FMOD_STUDIO_SYSTEM,
        pathOrID: *const c_char,
        bank: *mut *mut FMOD_STUDIO_BANK,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetEventByID(
        system: *mut FMOD_STUDIO_SYSTEM,
        id: *const FMOD_GUID,
        event: *mut *mut FMOD_STUDIO_EVENTDESCRIPTION,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetParameterDescriptionByID(
        system: *mut FMOD_STUDIO_SYSTEM,
        id: FMOD_STUDIO_PARAMETER_ID,
        parameter: *mut FMOD_STUDIO_PARAMETER_DESCRIPTION,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetParameterLabelByID(
        system: *mut FMOD_STUDIO_SYSTEM,
        id: FMOD_STUDIO_PARAMETER_ID,
        labelindex: c_int,
        label: *mut c_char,
        size: c_int,
        retrieved: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_LookupID(
        system: *mut FMOD_STUDIO_SYSTEM,
        path: *const c_char,
        id: *mut FMOD_GUID,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_LookupPath(
        system: *mut FMOD_STUDIO_SYSTEM,
        id: *const FMOD_GUID,
        path: *mut c_char,
        size: c_int,
        retrieved: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_LoadBankFile(
        system: *mut FMOD_STUDIO_SYSTEM,
        filename: *const c_char,
        flags: FMOD_STUDIO_LOAD_BANK_FLAGS,
        bank: *mut *mut FMOD_STUDIO_BANK,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_FlushCommands(system: *mut FMOD_STUDIO_SYSTEM) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetBankCount(
        system: *mut FMOD_STUDIO_SYSTEM,
        count: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetBankList(
        system: *mut FMOD_STUDIO_SYSTEM,
        array: *mut *mut FMOD_STUDIO_BANK,
        capacity: c_int,
        count: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetParameterDescriptionCount(
        system: *mut FMOD_STUDIO_SYSTEM,
        count: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_System_GetParameterDescriptionList(
        system: *mut FMOD_STUDIO_SYSTEM,
        array: *mut FMOD_STUDIO_PARAMETER_DESCRIPTION,
        capacity: c_int,
        count: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetPath(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        path: *mut c_char,
        size: c_int,
        retrieved: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetParameterDescriptionCount(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        count: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetParameterDescriptionByIndex(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        index: c_int,
        parameter: *mut FMOD_STUDIO_PARAMETER_DESCRIPTION,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetParameterDescriptionByID(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        id: FMOD_STUDIO_PARAMETER_ID,
        parameter: *mut FMOD_STUDIO_PARAMETER_DESCRIPTION,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetParameterLabelByIndex(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        index: c_int,
        labelindex: c_int,
        label: *mut c_char,
        size: c_int,
        retrieved: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetUserPropertyCount(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        count: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetUserPropertyByIndex(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        index: c_int,
        property: *mut FMOD_STUDIO_USER_PROPERTY,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetUserProperty(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        name: *const c_char,
        property: *mut FMOD_STUDIO_USER_PROPERTY,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetLength(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        length: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetMinMaxDistance(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        min: *mut c_float,
        max: *mut c_float,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetSoundSize(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        size: *mut c_float,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetInstanceCount(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        count: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_EventDescription_GetSampleLoadingState(
        eventdescription: *mut FMOD_STUDIO_EVENTDESCRIPTION,
        state: *mut FMOD_STUDIO_LOADING_STATE,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_Bus_GetPath(
        bus: *mut FMOD_STUDIO_BUS,
        path: *mut c_char,
        size: c_int,
        retrieved: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_Bus_GetVolume(
        bus: *mut FMOD_STUDIO_BUS,
        volume: *mut c_float,
        finalvolume: *mut c_float,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_Bus_GetPaused(
        bus: *mut FMOD_STUDIO_BUS,
        paused: *mut FMOD_BOOL,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_Bus_GetMute(bus: *mut FMOD_STUDIO_BUS, mute: *mut FMOD_BOOL) -> FMOD_RESULT;

pub fn FMOD_Studio_VCA_GetPath(
        vca: *mut FMOD_STUDIO_VCA,
        path: *mut c_char,
        size: c_int,
        retrieved: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_VCA_GetVolume(
        vca: *mut FMOD_STUDIO_VCA,
        volume: *mut c_float,
        finalvolume: *mut c_float,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_Bank_GetPath(
        bank: *mut FMOD_STUDIO_BANK,
        path: *mut c_char,
        size: c_int,
        retrieved: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_Bank_GetLoadingState(
        bank: *mut FMOD_STUDIO_BANK,
        state: *mut FMOD_STUDIO_LOADING_STATE,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_Bank_GetSampleLoadingState(
        bank: *mut FMOD_STUDIO_BANK,
        state: *mut FMOD_STUDIO_LOADING_STATE,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_Bank_GetStringCount(
        bank: *mut FMOD_STUDIO_BANK,
        count: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_Studio_Bank_GetStringInfo(
        bank: *mut FMOD_STUDIO_BANK,
        index: c_int,
        id: *mut FMOD_GUID,
        path: *mut c_char,
        size: c_int,
        retrieved: *mut c_int,
    ) -> FMOD_RESULT;

pub fn FMOD_System_Create(system: *mut *mut FMOD_SYSTEM, headerversion: c_uint) -> FMOD_RESULT;

pub fn FMOD_System_Release(system: *mut FMOD_SYSTEM) -> FMOD_RESULT;

pub fn FMOD_System_SetOutput(system: *mut FMOD_SYSTEM, output: FMOD_OUTPUTTYPE) -> FMOD_RESULT;

pub fn FMOD_System_Init(
        system: *mut FMOD_SYSTEM,
        maxchannels: c_int,
        flags: FMOD_INITFLAGS,
        extradriverdata: *mut c_void,
    ) -> FMOD_RESULT;

pub fn FMOD_System_GetVersion(system: *mut FMOD_SYSTEM, version: *mut c_uint) -> FMOD_RESULT;