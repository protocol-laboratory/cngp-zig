pub const CommandId = enum(u32) {
    Login = 0x00000001,
    LoginResp = 0x80000001,
    Submit = 0x00000002,
    SubmitResp = 0x80000002,
    Deliver = 0x00000003,
    DeliverResp = 0x80000003,
    ActiveTest = 0x00000004,
    ActiveTestResp = 0x80000004,
    Exit = 0x00000006,
    ExitResp = 0x80000006,
};
