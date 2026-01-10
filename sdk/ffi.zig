pub extern "m5" fn api_version() i32;
pub extern "m5" fn api_features() i64;
pub extern "m5" fn last_error_code() i32;
pub extern "m5" fn last_error_message(out: [*]u8, out_len: usize) i32;
pub extern "m5" fn heap_check(label: [*:0]const u8, print_errors: i32) i32;
pub extern "m5" fn heap_log(label: [*:0]const u8) void;
pub extern "m5" fn open_app(app_id: [*:0]const u8, arguments: [*:0]const u8) i32;
pub extern "m5" fn exit_app() i32;

pub extern "m5" fn begin() i32;
pub extern "m5" fn delay_ms(ms: i32) i32;
pub extern "m5" fn millis() i32;
pub extern "m5" fn micros() i64;

pub extern "m5_log" fn log_info(msg: [*:0]const u8) void;
pub extern "m5_log" fn log_warn(msg: [*:0]const u8) void;
pub extern "m5_log" fn log_error(msg: [*:0]const u8) void;

// Developer mode devserver
pub extern "m5_devserver" fn devserver_start() i32;
pub extern "m5_devserver" fn devserver_stop() i32;
pub extern "m5_devserver" fn devserver_is_running() i32;
pub extern "m5_devserver" fn devserver_is_starting() i32;
pub extern "m5_devserver" fn devserver_get_url(out: [*]u8, out_len: usize) i32;
pub extern "m5_devserver" fn devserver_get_ap_ssid(out: [*]u8, out_len: usize) i32;
pub extern "m5_devserver" fn devserver_get_ap_password(out: [*]u8, out_len: usize) i32;
pub extern "m5_devserver" fn devserver_get_last_error(out: [*]u8, out_len: usize) i32;

pub extern "m5_display" fn width() i32;
pub extern "m5_display" fn height() i32;
pub extern "m5_display" fn get_rotation() i32;
pub extern "m5_display" fn set_rotation(rot: i32) i32;
pub extern "m5_display" fn clear() i32;
pub extern "m5_display" fn fill_screen(color: i32) i32;
pub extern "m5_display" fn display() i32;
pub extern "m5_display" fn display_rect(x: i32, y: i32, w: i32, h: i32) i32;
pub extern "m5_display" fn wait_display() i32;
pub extern "m5_display" fn start_write() i32;
pub extern "m5_display" fn end_write() i32;
pub extern "m5_display" fn set_brightness(v: i32) i32;
pub extern "m5_display" fn get_brightness() i32;
pub extern "m5_display" fn set_epd_mode(mode: i32) i32;
pub extern "m5_display" fn get_epd_mode() i32;
pub extern "m5_display" fn draw_pixel(x: i32, y: i32, color: i32) i32;
pub extern "m5_display" fn draw_rect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
pub extern "m5_display" fn fill_rect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
pub extern "m5_display" fn draw_fast_hline(x: i32, y: i32, w: i32, color: i32) i32;
pub extern "m5_display" fn draw_line(x0: i32, y0: i32, x1: i32, y1: i32, color: i32) i32;
pub extern "m5_display" fn fill_arc(x: i32, y: i32, r0: i32, r1: i32, angle0: f32, angle1: f32, color: i32) i32;

pub extern "m5_display" fn set_cursor(x: i32, y: i32) i32;
pub extern "m5_display" fn set_text_color(fg: i32, bg: i32, use_bg: i32) i32;
pub extern "m5_display" fn set_text_size(sx: f32, sy: f32) i32;
pub extern "m5_display" fn set_text_datum(datum: i32) i32;
pub extern "m5_display" fn set_text_font(font_id: i32) i32;
pub extern "m5_display" fn set_text_wrap(wrap_x: i32, wrap_y: i32) i32;
pub extern "m5_display" fn set_text_scroll(scroll: i32) i32;
pub extern "m5_display" fn set_text_encoding(utf8_enable: i32, cp437_enable: i32) i32;
pub extern "m5_display" fn draw_string(text: [*:0]const u8, x: i32, y: i32) i32;
pub extern "m5_display" fn text_width(text: [*:0]const u8) i32;
pub extern "m5_display" fn font_height() i32;

pub extern "m5_display" fn vlw_register(ptr: [*]const u8, len: usize) i32;
pub extern "m5_display" fn vlw_use(handle: i32) i32;
pub extern "m5_display" fn vlw_use_system(font_id: i32) i32;
pub extern "m5_display" fn vlw_unload() i32;
pub extern "m5_display" fn vlw_clear_all() i32;

pub extern "m5_display" fn draw_png(ptr: [*]const u8, len: usize, x: i32, y: i32) i32;
pub extern "m5_display" fn draw_xth_centered(ptr: [*]const u8, len: usize) i32;
pub extern "m5_display" fn draw_xtg_centered(ptr: [*]const u8, len: usize) i32;
pub extern "m5_display" fn draw_jpg_fit(ptr: [*]const u8, len: usize, x: i32, y: i32, max_w: i32, max_h: i32) i32;
pub extern "m5_display" fn draw_png_fit(ptr: [*]const u8, len: usize, x: i32, y: i32, max_w: i32, max_h: i32) i32;
pub extern "m5_display" fn draw_jpg_file(path: [*:0]const u8, x: i32, y: i32, max_w: i32, max_h: i32) i32;
pub extern "m5_display" fn draw_png_file(path: [*:0]const u8, x: i32, y: i32, max_w: i32, max_h: i32) i32;
pub extern "m5_display" fn push_image(
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

pub extern "m5_touch" fn touch_get_count() i32;
pub extern "m5_touch" fn touch_get_raw(index: i32, out: [*]u8, out_len: i32) i32;
pub extern "m5_touch" fn touch_get_detail(index: i32, out: [*]u8, out_len: i32) i32;
pub extern "m5_touch" fn touch_set_hold_thresh(ms: i32) i32;
pub extern "m5_touch" fn touch_set_flick_thresh(distance: i32) i32;

pub extern "m5_fs" fn fs_is_mounted() i32;
pub extern "m5_fs" fn fs_mount() i32;
pub extern "m5_fs" fn fs_unmount() i32;
pub extern "m5_fs" fn fs_open(path: [*:0]const u8, flags: i32) i32;
pub extern "m5_fs" fn fs_close(handle: i32) i32;
pub extern "m5_fs" fn fs_read(handle: i32, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_fs" fn fs_write(handle: i32, ptr: [*]const u8, len: i32) i32;
pub extern "m5_fs" fn fs_seek(handle: i32, offset: i32, whence: i32) i32;
pub extern "m5_fs" fn fs_stat(path: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_fs" fn fs_remove(path: [*:0]const u8) i32;
pub extern "m5_fs" fn fs_rename(from: [*:0]const u8, to: [*:0]const u8) i32;
pub extern "m5_fs" fn fs_opendir(path: [*:0]const u8) i32;
pub extern "m5_fs" fn fs_readdir(handle: i32, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_fs" fn fs_closedir(handle: i32) i32;
pub extern "m5_fs" fn fs_mkdir(path: [*:0]const u8) i32;
pub extern "m5_fs" fn fs_rmdir(path: [*:0]const u8) i32;
pub extern "m5_fs" fn fs_card_info(out_ptr: [*]u8, out_len: i32) i32;

pub extern "m5_nvs" fn nvs_open(namespace_name: [*:0]const u8, mode: i32) i32;
pub extern "m5_nvs" fn nvs_close(handle: i32) i32;

pub extern "m5_nvs" fn nvs_set_i8(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvs_set_u8(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvs_set_i16(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvs_set_u16(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvs_set_i32(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvs_set_u32(handle: i32, key: [*:0]const u8, value: i32) i32;
pub extern "m5_nvs" fn nvs_set_i64(handle: i32, key: [*:0]const u8, value: i64) i32;
pub extern "m5_nvs" fn nvs_set_u64(handle: i32, key: [*:0]const u8, value: i64) i32;
pub extern "m5_nvs" fn nvs_set_str(handle: i32, key: [*:0]const u8, value: [*:0]const u8) i32;
pub extern "m5_nvs" fn nvs_set_blob(handle: i32, key: [*:0]const u8, value: [*]const u8, len: i32) i32;

pub extern "m5_nvs" fn nvs_get_i8(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_u8(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_i16(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_u16(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_i32(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_u32(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_i64(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_u64(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_str(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_blob(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;

pub extern "m5_nvs" fn nvs_find_key(handle: i32, key: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_erase_key(handle: i32, key: [*:0]const u8) i32;
pub extern "m5_nvs" fn nvs_erase_all(handle: i32) i32;
pub extern "m5_nvs" fn nvs_commit(handle: i32) i32;

pub extern "m5_nvs" fn nvs_get_stats(partition_name: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_get_used_entry_count(handle: i32, out_ptr: [*]u8, out_len: i32) i32;

pub extern "m5_nvs" fn nvs_entry_find(partition_name: [*:0]const u8, namespace_name: [*:0]const u8, type_code: i32) i32;
pub extern "m5_nvs" fn nvs_entry_find_in_handle(handle: i32, type_code: i32) i32;
pub extern "m5_nvs" fn nvs_entry_next(iterator_handle: i32) i32;
pub extern "m5_nvs" fn nvs_entry_info(iterator_handle: i32, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_nvs" fn nvs_release_iterator(iterator_handle: i32) i32;

// Speaker functions
pub extern "m5_speaker" fn speaker_begin() i32;
pub extern "m5_speaker" fn speaker_end() i32;
pub extern "m5_speaker" fn speaker_is_enabled() i32;
pub extern "m5_speaker" fn speaker_is_running() i32;
pub extern "m5_speaker" fn speaker_set_volume(v: i32) i32;
pub extern "m5_speaker" fn speaker_get_volume() i32;
pub extern "m5_speaker" fn speaker_stop() i32;
pub extern "m5_speaker" fn speaker_tone(freq_hz: f32, duration_ms: i32) i32;
pub extern "m5_speaker" fn speaker_beeper_start(freq_hz: f32, beep_count: i32, duration_ms: i32, gap_ms: i32, pause_ms: i32) i32;
pub extern "m5_speaker" fn speaker_beeper_stop() i32;

// RTC functions
pub extern "m5_rtc" fn rtc_begin() i32;
pub extern "m5_rtc" fn rtc_is_enabled() i32;
pub extern "m5_rtc" fn rtc_get_datetime(out_ptr: [*]u8, out_len: usize) i32;
pub extern "m5_rtc" fn rtc_set_datetime(ptr: [*]const u8, len: usize) i32;
pub extern "m5_rtc" fn rtc_set_timer_irq(ms: i32) i32;
pub extern "m5_rtc" fn rtc_clear_irq() i32;
pub extern "m5_rtc" fn rtc_set_alarm_irq(seconds: i32) i32;

// Power functions
pub extern "m5_power" fn power_begin() i32;
pub extern "m5_power" fn power_battery_level() i32;
pub extern "m5_power" fn power_battery_voltage_mv() i32;
pub extern "m5_power" fn power_battery_current_ma() i32;
pub extern "m5_power" fn power_vbus_voltage_mv() i32;
pub extern "m5_power" fn power_is_charging() i32;
pub extern "m5_power" fn power_is_usb_connected() i32;
pub extern "m5_power" fn power_set_battery_charge(enable: i32) i32;
pub extern "m5_power" fn power_restart() i32;
pub extern "m5_power" fn power_light_sleep_us(us: i64) i32;
pub extern "m5_power" fn power_deep_sleep_us(us: i64) i32;
pub extern "m5_power" fn power_off() i32;

// IMU functions
pub extern "m5_imu" fn imu_begin() i32;
pub extern "m5_imu" fn imu_is_enabled() i32;
pub extern "m5_imu" fn imu_update() i32;
pub extern "m5_imu" fn imu_get_accel(out_ptr: [*]u8, out_len: usize) i32;
pub extern "m5_imu" fn imu_get_gyro(out_ptr: [*]u8, out_len: usize) i32;
pub extern "m5_imu" fn imu_get_temp(out_ptr: [*]u8, out_len: usize) i32;

// Net / Wi-Fi scan functions
pub extern "m5_net" fn net_is_ready() i32;
pub extern "m5_net" fn net_connect() i32;
pub extern "m5_net" fn net_disconnect() i32;
pub extern "m5_net" fn net_get_ipv4(out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_net" fn net_resolve_ipv4(host: [*:0]const u8, out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_net" fn wifi_scan_start() i32;
pub extern "m5_net" fn wifi_scan_is_running() i32;
pub extern "m5_net" fn wifi_scan_get_best(out_ptr: [*]u8, out_len: i32) i32;
pub extern "m5_net" fn wifi_scan_get_count() i32;
pub extern "m5_net" fn wifi_scan_get_record(index: i32, out_ptr: [*]u8, out_len: i32) i32;

// Socket functions
pub extern "m5_socket" fn sock_socket(domain: i32, socket_type: i32, protocol: i32) i32;
pub extern "m5_socket" fn sock_connect(sockfd: i32, addr_ptr: [*]const u8, addr_len: i32, timeout_ms: i32) i32;
pub extern "m5_socket" fn sock_bind(sockfd: i32, addr_ptr: [*]const u8, addr_len: i32) i32;
pub extern "m5_socket" fn sock_listen(sockfd: i32, backlog: i32) i32;
pub extern "m5_socket" fn sock_accept(sockfd: i32, out_addr_ptr: [*]u8, out_addr_len: i32) i32;
pub extern "m5_socket" fn sock_accept_with_timeout(sockfd: i32, out_addr_ptr: [*]u8, out_addr_len: i32, timeout_ms: i32) i32;
pub extern "m5_socket" fn sock_send(sockfd: i32, buf_ptr: [*]const u8, buf_len: i32, timeout_ms: i32) i32;
pub extern "m5_socket" fn sock_recv(sockfd: i32, buf_ptr: [*]u8, buf_len: i32, timeout_ms: i32) i32;
pub extern "m5_socket" fn sock_close(sockfd: i32) i32;

// HAL functions (misc)
pub extern "m5_hal" fn ext_port_test_start() i32;

// FastEPD functions
pub extern "fast_epd" fn epd_init_panel(panel_type: i32, speed: i32) i32;
pub extern "fast_epd" fn epd_init_lights(led1: i32, led2: i32) i32;
pub extern "fast_epd" fn epd_set_brightness(led1: i32, led2: i32) i32;
pub extern "fast_epd" fn epd_set_mode(mode: i32) i32;
pub extern "fast_epd" fn epd_get_mode() i32;
pub extern "fast_epd" fn epd_set_panel_size_preset(panel_id: i32) i32;
pub extern "fast_epd" fn epd_set_panel_size(width: i32, height: i32, flags: i32, vcom_mv: i32) i32;
pub extern "fast_epd" fn epd_set_custom_matrix(ptr: [*]const u8, len: usize) i32;
pub extern "fast_epd" fn epd_width() i32;
pub extern "fast_epd" fn epd_height() i32;
pub extern "fast_epd" fn epd_get_rotation() i32;
pub extern "fast_epd" fn epd_set_rotation(rotation: i32) i32;
pub extern "fast_epd" fn epd_fill_screen(color: i32) i32;
pub extern "fast_epd" fn epd_draw_pixel(x: i32, y: i32, color: i32) i32;
pub extern "fast_epd" fn epd_draw_pixel_fast(x: i32, y: i32, color: i32) i32;
pub extern "fast_epd" fn epd_draw_line(x1: i32, y1: i32, x2: i32, y2: i32, color: i32) i32;
pub extern "fast_epd" fn epd_draw_rect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
pub extern "fast_epd" fn epd_fill_rect(x: i32, y: i32, w: i32, h: i32, color: i32) i32;
pub extern "fast_epd" fn epd_draw_circle(x: i32, y: i32, r: i32, color: i32) i32;
pub extern "fast_epd" fn epd_fill_circle(x: i32, y: i32, r: i32, color: i32) i32;
pub extern "fast_epd" fn epd_draw_round_rect(x: i32, y: i32, w: i32, h: i32, r: i32, color: i32) i32;
pub extern "fast_epd" fn epd_fill_round_rect(x: i32, y: i32, w: i32, h: i32, r: i32, color: i32) i32;
pub extern "fast_epd" fn epd_draw_triangle(x0: i32, y0: i32, x1: i32, y1: i32, x2: i32, y2: i32, color: i32) i32;
pub extern "fast_epd" fn epd_fill_triangle(x0: i32, y0: i32, x1: i32, y1: i32, x2: i32, y2: i32, color: i32) i32;
pub extern "fast_epd" fn epd_set_text_color(fg: i32, bg: i32) i32;
pub extern "fast_epd" fn epd_set_cursor(x: i32, y: i32) i32;
pub extern "fast_epd" fn epd_set_font(font: i32) i32;
pub extern "fast_epd" fn epd_set_text_wrap(wrap: i32) i32;
pub extern "fast_epd" fn epd_draw_string(text: [*:0]const u8, x: i32, y: i32) i32;
pub extern "fast_epd" fn epd_get_string_box(text: [*:0]const u8, out: [*]u8, out_len: i32) i32;
pub extern "fast_epd" fn epd_full_update(clear_mode: i32, keep_on: i32) i32;
pub extern "fast_epd" fn epd_full_update_rect(clear_mode: i32, keep_on: i32, x: i32, y: i32, w: i32, h: i32) i32;
pub extern "fast_epd" fn epd_partial_update(keep_on: i32, start_row: i32, end_row: i32) i32;
pub extern "fast_epd" fn epd_smooth_update(keep_on: i32, color: i32) i32;
pub extern "fast_epd" fn epd_clear_white(keep_on: i32) i32;
pub extern "fast_epd" fn epd_clear_black(keep_on: i32) i32;
pub extern "fast_epd" fn epd_backup_plane() i32;
pub extern "fast_epd" fn epd_invert_rect(x: i32, y: i32, w: i32, h: i32) i32;
pub extern "fast_epd" fn epd_io_pin_mode(pin: i32, mode: i32) i32;
pub extern "fast_epd" fn epd_io_write(pin: i32, value: i32) i32;
pub extern "fast_epd" fn epd_io_read(pin: i32) i32;
pub extern "fast_epd" fn epd_eink_power(on: i32) i32;
pub extern "fast_epd" fn epd_load_bmp(ptr: [*]const u8, len: usize, x: i32, y: i32, fg: i32, bg: i32) i32;
pub extern "fast_epd" fn epd_load_g5_image(ptr: [*]const u8, len: usize, x: i32, y: i32, fg: i32, bg: i32, scale: f32) i32;
pub extern "fast_epd" fn epd_set_passes(partial_passes: i32, full_passes: i32) i32;
pub extern "fast_epd" fn epd_deinit() i32;
