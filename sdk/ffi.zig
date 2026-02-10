pub extern "m5" fn apiVersion() i32;
pub extern "m5" fn apiFeatures() i64;
pub extern "m5" fn lastErrorCode() i32;
pub extern "m5" fn lastErrorMessage(out: [*]u8, out_len: usize) i32;
pub extern "m5" fn heapCheck(label: [*:0]const u8, print_errors: i32) i32;
pub extern "m5" fn heapLog(label: [*:0]const u8) void;
pub extern "m5" fn openApp(app_id: [*:0]const u8, arguments: [*:0]const u8) i32;
pub extern "m5" fn exitApp() i32;
pub extern "m5" fn begin() i32;
pub extern "m5" fn delayMs(ms: i32) i32;
pub extern "m5" fn millis() i32;
pub extern "m5" fn micros() i64;
pub extern "m5_log" fn logInfo(msg: [*:0]const u8) void;
pub extern "m5_log" fn logWarn(msg: [*:0]const u8) void;
pub extern "m5_log" fn logError(msg: [*:0]const u8) void;

// Developer mode devserver

pub extern "m5_devserver" fn devserverStart() i32;
pub extern "m5_devserver" fn devserverStop() i32;
pub extern "m5_devserver" fn devserverIsRunning() i32;
pub extern "m5_devserver" fn devserverIsStarting() i32;
pub extern "m5_devserver" fn devserverGetUrl(out: [*]u8, out_len: usize) i32;
pub extern "m5_devserver" fn devserverGetApSsid(out: [*]u8, out_len: usize) i32;
pub extern "m5_devserver" fn devserverGetApPassword(out: [*]u8, out_len: usize) i32;
pub extern "m5_devserver" fn devserverGetLastError(out: [*]u8, out_len: usize) i32;
pub extern "m5_display" fn width() i32;
pub extern "m5_display" fn height() i32;
pub extern "m5_display" fn getRotation() i32;
pub extern "m5_display" fn setRotation(rot: i32) i32;
pub extern "m5_display" fn clear() i32;
pub extern "m5_display" fn fillScreen(color: i32) i32;
pub extern "m5_display" fn display() i32;
pub extern "m5_display" fn displayRect(x: i32, y: i32, w: i32, h: i32) i32;
pub extern "m5_display" fn waitDisplay() i32;
pub extern "m5_display" fn startWrite() i32;
pub extern "m5_display" fn endWrite() i32;
pub extern "m5_display" fn setBrightness(v: i32) i32;
pub extern "m5_display" fn getBrightness() i32;
pub extern "m5_display" fn setEpdMode(mode: i32) i32;
pub extern "m5_display" fn getEpdMode() i32;
pub extern "m5_display" fn drawPixel(x: i32, y: i32, color: i32) i32;
pub extern "m5_display" fn drawRect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
pub extern "m5_display" fn fillRect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
pub extern "m5_display" fn drawFastHline(x: i32, y: i32, w: i32, color: i32) i32;
pub extern "m5_display" fn drawLine(x0: i32, y0: i32, x1: i32, y1: i32, color: i32) i32;
pub extern "m5_display" fn fillArc(x: i32, y: i32, r0: i32, r1: i32, angle0: f32, angle1: f32, color: i32) i32;
pub extern "m5_display" fn setCursor(x: i32, y: i32) i32;
pub extern "m5_display" fn setTextColor(fg: i32, bg: i32, use_bg: i32) i32;
pub extern "m5_display" fn setTextSize(sx: f32, sy: f32) i32;
pub extern "m5_display" fn setTextDatum(datum: i32) i32;
pub extern "m5_display" fn setTextFont(font_id: i32) i32;
pub extern "m5_display" fn setTextWrap(wrap_x: i32, wrap_y: i32) i32;
pub extern "m5_display" fn setTextScroll(scroll: i32) i32;
pub extern "m5_display" fn setTextEncoding(utf8_enable: i32, cp437_enable: i32) i32;
pub extern "m5_display" fn drawString(text: [*:0]const u8, x: i32, y: i32) i32;
pub extern "m5_display" fn textWidth(text: [*:0]const u8) i32;
pub extern "m5_display" fn fontHeight() i32;
pub extern "m5_display" fn vlwRegister(ptr: [*]const u8, len: usize) i32;
pub extern "m5_display" fn vlwUse(handle: i32) i32;
pub extern "m5_display" fn vlwUseSystem(font_id: i32) i32;
pub extern "m5_display" fn vlwUnload() i32;
pub extern "m5_display" fn vlwClearAll() i32;
pub extern "m5_display" fn drawPng(ptr: [*]const u8, len: usize, x: i32, y: i32) i32;
pub extern "m5_display" fn drawXthCentered(ptr: [*]const u8, len: usize) i32;
pub extern "m5_display" fn drawXtgCentered(ptr: [*]const u8, len: usize) i32;
pub extern "m5_display" fn drawJpgFit(ptr: [*]const u8, len: usize, x: i32, y: i32, max_w: i32, max_h: i32) i32;
pub extern "m5_display" fn drawPngFit(ptr: [*]const u8, len: usize, x: i32, y: i32, max_w: i32, max_h: i32) i32;
pub extern "m5_display" fn drawJpgFile(path: [*:0]const u8, x: i32, y: i32, max_w: i32, max_h: i32) i32;
pub extern "m5_display" fn drawPngFile(path: [*:0]const u8, x: i32, y: i32, max_w: i32, max_h: i32) i32;
pub extern "m5_display" fn pushImage(
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    data_ptr: [*]const u8,
    data_len: usize,
    depth: i32,
    palette_ptr: ?[*]const u8,
    palette_len: usize,
) i32;
pub extern "m5_touch" fn touchGetCount() i32;
pub extern "m5_touch" fn touchGetRaw(index: i32, out: [*]u8, out_len: i32) i32;
pub extern "m5_touch" fn touchGetDetail(index: i32, out: [*]u8, out_len: i32) i32;
pub extern "m5_touch" fn touchSetHoldThresh(ms: i32) i32;
pub extern "m5_touch" fn touchSetFlickThresh(distance: i32) i32;

// Custom gesture recognition

pub extern "m5_gesture" fn gestureClearAll() i32;
pub extern "m5_gesture" fn gestureRegisterPolyline(
    id: [*:0]const u8,
    points_ptr: [*]const u8,
    points_len: i32,
    fixed: i32,
    tolerance_px: f32,
    priority: i32,
    max_duration_ms: i32,
    options: i32,
) i32;
pub extern "m5_gesture" fn gestureRemove(handle: i32) i32;

pub extern "m5_fs" fn fsIsMounted() i32;
pub extern "m5_fs" fn fsMount() i32;
pub extern "m5_fs" fn fsUnmount() i32;
pub extern "m5_fs" fn fsOpen(path: [*:0]const u8, flags: i32) i32;
pub extern "m5_fs" fn fsClose(handle: i32) i32;
pub extern "m5_fs" fn fsRead(handle: i32, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_fs" fn fsWrite(handle: i32, ptr: [*]const u8, len: i32) i32;
pub extern "m5_fs" fn fsSeek(handle: i32, offset: i32, whence: i32) i32;
pub extern "m5_fs" fn fsStat(path: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_fs" fn fsRemove(path: [*:0]const u8) i32;
pub extern "m5_fs" fn fsRename(from: [*:0]const u8, to: [*:0]const u8) i32;
pub extern "m5_fs" fn fsOpendir(path: [*:0]const u8) i32;
pub extern "m5_fs" fn fsReaddir(handle: i32, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_fs" fn fsClosedir(handle: i32) i32;
pub extern "m5_fs" fn fsMkdir(path: [*:0]const u8) i32;
pub extern "m5_fs" fn fsRmdir(path: [*:0]const u8) i32;
pub extern "m5_fs" fn fsCardInfo(out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsOpen(namespace_name: [*:0]const u8, mode: i32) i32;
pub extern "m5_nvs" fn nvsClose(handle: i32) i32;
pub extern "m5_nvs" fn nvsSetI8(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvsSetU8(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvsSetI16(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvsSetU16(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvsSetI32(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvsSetU32(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvsSetI64(handle: i32, key: [*:0]const u8, value: i64) i32;
pub extern "m5_nvs" fn nvsSetU64(handle: i32, key: [*:0]const u8, value: i64) i32;
pub extern "m5_nvs" fn nvsSetStr(handle: i32, key: [*:0]const u8, value: [*:0]const u8) i32;
pub extern "m5_nvs" fn nvsSetBlob(handle: i32, key: [*:0]const u8, value: [*]const u8, len: i32) i32;
pub extern "m5_nvs" fn nvsGetI8(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetU8(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetI16(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetU16(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetI32(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetU32(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetI64(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetU64(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetStr(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetBlob(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsFindKey(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsEraseKey(handle: i32, key: [*:0]const u8) i32;
pub extern "m5_nvs" fn nvsEraseAll(handle: i32) i32;
pub extern "m5_nvs" fn nvsCommit(handle: i32) i32;
pub extern "m5_nvs" fn nvsGetStats(partition_name: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsGetUsedEntryCount(handle: i32, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsEntryFind(partition_name: [*:0]const u8, namespace_name: [*:0]const u8, type_code: i32) i32;
pub extern "m5_nvs" fn nvsEntryFindInHandle(handle: i32, type_code: i32) i32;
pub extern "m5_nvs" fn nvsEntryNext(iterator_handle: i32) i32;
pub extern "m5_nvs" fn nvsEntryInfo(iterator_handle: i32, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvsReleaseIterator(iterator_handle: i32) i32;

// Speaker functions

pub extern "m5_speaker" fn speakerBegin() i32;
pub extern "m5_speaker" fn speakerEnd() i32;
pub extern "m5_speaker" fn speakerIsEnabled() i32;
pub extern "m5_speaker" fn speakerIsRunning() i32;
pub extern "m5_speaker" fn speakerSetVolume(v: i32) i32;
pub extern "m5_speaker" fn speakerGetVolume() i32;
pub extern "m5_speaker" fn speakerStop() i32;
pub extern "m5_speaker" fn speakerTone(freq_hz: f32, duration_ms: i32) i32;
pub extern "m5_speaker" fn speakerBeeperStart(freq_hz: f32, beep_count: i32, duration_ms: i32, gap_ms: i32, pause_ms: i32) i32;
pub extern "m5_speaker" fn speakerBeeperStop() i32;

// RTC functions

pub extern "m5_rtc" fn rtcBegin() i32;
pub extern "m5_rtc" fn rtcIsEnabled() i32;
pub extern "m5_rtc" fn rtcGetDatetime(out_ptr: [*]u8, out_len: usize) i32;
pub extern "m5_rtc" fn rtcSetDatetime(ptr: [*]const u8, len: usize) i32;
pub extern "m5_rtc" fn rtcSetTimerIrq(ms: i32) i32;
pub extern "m5_rtc" fn rtcClearIrq() i32;
pub extern "m5_rtc" fn rtcSetAlarmIrq(seconds: i32) i32;

// Power functions

pub extern "m5_power" fn powerBegin() i32;
pub extern "m5_power" fn powerBatteryLevel() i32;
pub extern "m5_power" fn powerBatteryVoltageMv() i32;
pub extern "m5_power" fn powerBatteryCurrentMa() i32;
pub extern "m5_power" fn powerVbusVoltageMv() i32;
pub extern "m5_power" fn powerIsCharging() i32;
pub extern "m5_power" fn powerIsUsbConnected() i32;
pub extern "m5_power" fn powerSetBatteryCharge(enable: i32) i32;
pub extern "m5_power" fn powerRestart() i32;
pub extern "m5_power" fn powerLightSleepUs(us: i64) i32;
pub extern "m5_power" fn powerDeepSleepUs(us: i64) i32;
pub extern "m5_power" fn powerOff() i32;
pub extern "m5_power" fn powerOffWithSleepImage(show_sleep_image: i32) i32;

// IMU functions

pub extern "m5_imu" fn imuBegin() i32;
pub extern "m5_imu" fn imuIsEnabled() i32;
pub extern "m5_imu" fn imuUpdate() i32;
pub extern "m5_imu" fn imuGetAccel(out_ptr: [*]u8, out_len: usize) i32;
pub extern "m5_imu" fn imuGetGyro(out_ptr: [*]u8, out_len: usize) i32;
pub extern "m5_imu" fn imuGetTemp(out_ptr: [*]u8, out_len: usize) i32;

// Net / Wi-Fi scan functions

pub extern "m5_net" fn netIsReady() i32;
pub extern "m5_net" fn netConnect() i32;
pub extern "m5_net" fn netDisconnect() i32;
pub extern "m5_net" fn netGetIpv4(out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_net" fn netResolveIpv4(host: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_net" fn wifiScanStart() i32;
pub extern "m5_net" fn wifiScanIsRunning() i32;
pub extern "m5_net" fn wifiScanGetBest(out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_net" fn wifiScanGetCount() i32;
pub extern "m5_net" fn wifiScanGetRecord(index: i32, out_ptr: [*]u8, out_len: i32) i32;

// Socket functions

pub extern "m5_socket" fn sockSocket(domain: i32, socket_type: i32, protocol: i32) i32;
pub extern "m5_socket" fn sockConnect(sockfd: i32, addr_ptr: [*]const u8, addr_len: i32, timeout_ms: i32) i32;
pub extern "m5_socket" fn sockBind(sockfd: i32, addr_ptr: [*]const u8, addr_len: i32) i32;
pub extern "m5_socket" fn sockListen(sockfd: i32, backlog: i32) i32;
pub extern "m5_socket" fn sockAccept(sockfd: i32, out_addr_ptr: [*]u8, out_addr_len: i32) i32;
pub extern "m5_socket" fn sockAcceptWithTimeout(sockfd: i32, out_addr_ptr: [*]u8, out_addr_len: i32, timeout_ms: i32) i32;
pub extern "m5_socket" fn sockSend(sockfd: i32, buf_ptr: [*]const u8, buf_len: i32, timeout_ms: i32) i32;
pub extern "m5_socket" fn sockRecv(sockfd: i32, buf_ptr: [*]u8, buf_len: i32, timeout_ms: i32) i32;
pub extern "m5_socket" fn sockClose(sockfd: i32) i32;

// HAL functions (misc)

pub extern "m5_hal" fn extPortTestStart() i32;

// FastEPD functions

pub extern "fast_epd" fn epdInitPanel(panel_type: i32, speed: i32) i32;
pub extern "fast_epd" fn epdInitLights(led1: i32, led2: i32) i32;
pub extern "fast_epd" fn epdSetBrightness(led1: i32, led2: i32) i32;
pub extern "fast_epd" fn epdSetMode(mode: i32) i32;
pub extern "fast_epd" fn epdGetMode() i32;
pub extern "fast_epd" fn epdSetPanelSizePreset(panel_id: i32) i32;
pub extern "fast_epd" fn epdSetPanelSize(width: i32, height: i32, flags: i32, vcom_mv: i32) i32;
pub extern "fast_epd" fn epdSetCustomMatrix(ptr: [*]const u8, len: usize) i32;
pub extern "fast_epd" fn epdWidth() i32;
pub extern "fast_epd" fn epdHeight() i32;
pub extern "fast_epd" fn epdGetRotation() i32;
pub extern "fast_epd" fn epdSetRotation(rotation: i32) i32;
pub extern "fast_epd" fn epdFillScreen(color: i32) i32;
pub extern "fast_epd" fn epdDrawPixel(x: i32, y: i32, color: i32) i32;
pub extern "fast_epd" fn epdDrawPixelFast(x: i32, y: i32, color: i32) i32;
pub extern "fast_epd" fn epdDrawLine(x1: i32, y1: i32, x2: i32, y2: i32, color: i32) i32;
pub extern "fast_epd" fn epdDrawRect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
pub extern "fast_epd" fn epdFillRect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
pub extern "fast_epd" fn epdDrawCircle(x: i32, y: i32, r: i32, color: i32) i32;
pub extern "fast_epd" fn epdFillCircle(x: i32, y: i32, r: i32, color: i32) i32;
pub extern "fast_epd" fn epdDrawRoundRect(x: i32, y: i32, w: i32, h: i32, r: i32, color: i32) i32;
pub extern "fast_epd" fn epdFillRoundRect(x: i32, y: i32, w: i32, h: i32, r: i32, color: i32) i32;
pub extern "fast_epd" fn epdDrawTriangle(x0: i32, y0: i32, x1: i32, y1: i32, x2: i32, y2: i32, color: i32) i32;
pub extern "fast_epd" fn epdFillTriangle(x0: i32, y0: i32, x1: i32, y1: i32, x2: i32, y2: i32, color: i32) i32;
pub extern "fast_epd" fn epdSetTextColor(fg: i32, bg: i32) i32;
pub extern "fast_epd" fn epdSetCursor(x: i32, y: i32) i32;
pub extern "fast_epd" fn epdSetFont(font: i32) i32;
pub extern "fast_epd" fn epdSetTextWrap(wrap: i32) i32;
pub extern "fast_epd" fn epdDrawString(text: [*:0]const u8, x: i32, y: i32) i32;
pub extern "fast_epd" fn epdGetStringBox(text: [*:0]const u8, out: [*]u8, out_len: i32) i32;
pub extern "fast_epd" fn epdFullUpdate(clear_mode: i32, keep_on: i32) i32;
pub extern "fast_epd" fn epdFullUpdateRect(clear_mode: i32, keep_on: i32, x: i32, y: i32, w: i32, h: i32) i32;
pub extern "fast_epd" fn epdPartialUpdate(keep_on: i32, start_row: i32, end_row: i32) i32;
pub extern "fast_epd" fn epdSmoothUpdate(keep_on: i32, color: i32) i32;
pub extern "fast_epd" fn epdClearWhite(keep_on: i32) i32;
pub extern "fast_epd" fn epdClearBlack(keep_on: i32) i32;
pub extern "fast_epd" fn epdBackupPlane() i32;
pub extern "fast_epd" fn epdInvertRect(x: i32, y: i32, w: i32, h: i32) i32;
pub extern "fast_epd" fn epdIoPinMode(pin: i32, mode: i32) i32;
pub extern "fast_epd" fn epdIoWrite(pin: i32, value: i32) i32;
pub extern "fast_epd" fn epdIoRead(pin: i32) i32;
pub extern "fast_epd" fn epdEinkPower(on: i32) i32;
pub extern "fast_epd" fn epdLoadBmp(ptr: [*]const u8, len: usize, x: i32, y: i32, fg: i32, bg: i32) i32;
pub extern "fast_epd" fn epdLoadG5Image(ptr: [*]const u8, len: usize, x: i32, y: i32, fg: i32, bg: i32, scale: f32) i32;
pub extern "fast_epd" fn epdSetPasses(partial_passes: i32, full_passes: i32) i32;
pub extern "fast_epd" fn epdDeinit() i32;
