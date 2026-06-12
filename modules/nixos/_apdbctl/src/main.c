#include <assert.h>
#include <errno.h>
#include <hidapi.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(__APPLE__)
#include <libkern/OSByteOrder.h>
#define htole32(x) OSSwapHostToLittleInt32(x)
#define le16toh(x) OSSwapLittleToHostInt16(x)
#define le32toh(x) OSSwapLittleToHostInt32(x)
#else
#include <endian.h>
#endif

#define APPLE_INC 0x05ac
#define PRO_DISPLAY_XDR 0x9243
#define BRIGHTNESS_REPORT_ID 0x1
#define BRIGHTNESS_REPORT_PAGE 0x8005
#define BRIGHTNESS_REPORT_USAGE 0x1009
#define BRIGHTNESS_MIN 0x0190  // 400
#define BRIGHTNESS_MAX 0xc350  // 50_000
#define BRIGHTNESS_RANGE (BRIGHTNESS_MAX - BRIGHTNESS_MIN)

#if BRIGHTNESS_MIN >= BRIGHTNESS_MAX
#error "BRIGHTNESS_MIN must be strictly less than BRIGHTNESS_MAX"
#endif

#define SUCCESS 0
#define ERR_INVALID_ARGUMENT 1
#define ERR_DEVICE_NOT_FOUND 2
#define ERR_HIDAPI_CALL_FAIL 3
#define ERR_INVALID_PRECONDITION 4

/**
 * @brief Prints usage on standard error.
 *
 * @param program_name[in] The name of the program, typically `argv[0]`.
 */
static void print_usage(const char* program_name) {
  // clang-format off
  fprintf(stderr, "%s v%s, vendored in 0xcharly/nix-config\n", PROJECT_NAME, VERSION);
  fprintf(stderr, "\n");
  fprintf(stderr, "Usage: %s <command> [arguments]\n", program_name);
  fprintf(stderr, "Commands:\n");
  fprintf(stderr, "  get [-%% | -p | --percent]  Get current brightness (absolute or percentage)\n");
  fprintf(stderr, "  set <value>                Set brightness to value (integer or percentage)\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Brightness value:\n");
  fprintf(stderr, "  Valid integer values are in the range [400, 50000], inclusive.\n");
  fprintf(stderr, "  Percentage values are also accepted, e.g. \"50%%\".\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Examples:\n");
  fprintf(stderr, "  %s set 400\n", program_name);
  fprintf(stderr, "  %s set 30%\n", program_name);
  // clang-format on
}

/**
 * @brief Checks whether a device is from an Apple Pro Display XDR.
 *
 * The Pro Display XDR advertises 4 HID interfaces, but only one of them is capable of brightness
 * control. This only checks if this is one of the 4 advertised interfaces.
 *
 * @param device[in] The HID device to inspect.
 * @return Whether the device's vendor and product IDs matches that of the Apple Pro Display XDR.
 * @see hid_is_apple_pro_display_xdr_brightness_control_device
 */
static bool is_apple_pro_display_xdr_device(struct hid_device_info* device) {
  return device->vendor_id == APPLE_INC && device->product_id == PRO_DISPLAY_XDR;
}

/**
 * @brief A HID report descriptor prefix.
 *
 * This descriptor is incomplete and only intended to match the first bytes of the Apple Pro Display
 * XDR brightness control device descriptor.
 *
 * @param usage_page HID usage page (global item) indicating the category of controls.
 * @param usage HID usage (global item) indicating the specific control within the page.
 * @param collection Collection type (e.g., application or logical grouping of controls).
 * @param report_id Report ID identifying this report for multi-report devices.
 * @param report_usage_pages Array of usage pages referenced in the report (local items).
 * @param report_usage Usage referenced in the report (local item).
 * @param logical_minimum_size Size in bytes of the logical minimum field.
 * @param logical_minimum Logical minimum value allowed for the control.
 * @param logical_maximum_size Size in bytes of the logical maximum field.
 * @param logical_maximum Logical maximum value allowed for the control.
 * @param unit HID unit descriptor bytes (specifies measurement units).
 * @param unit_exponent Exponent used with unit to scale the reported value.
 * @param report_size Size in bits of each element in the report.
 * @param report_count Number of elements in the report.
 * @param feature Feature flag for the report (typically the feature ID or type).
 */
struct __attribute__((packed)) hid_report_descriptor {
  uint16_t usage_page;
  uint16_t usage;
  uint16_t collection;
  uint16_t report_id;
  uint8_t report_usage_pages[3];
  uint16_t report_usage;
  uint8_t logical_minimum_size;
  int16_t logical_minimum;
  uint8_t logical_maximum_size;
  int32_t logical_maximum;
  uint8_t unit[5];
  uint16_t unit_exponent;
  uint16_t report_size;
  uint16_t report_count;
  uint16_t feature;
};

/**
 * @brief Checks whether a device is an Apple Pro Display XDR brightness control device.
 *
 * The Pro Display XDR advertises 4 HID interfaces, but only one of them is capable of brightness
 * control. This only checks if the report descriptor of the given `device` matches the Apple Pro
 * Display XDR brightness control device.
 *
 * @param device[in] The HID device to inspect.
 * @return Whether the device's report descriptor matches that of the Apple Pro Display XDR
 *   brightness control device.
 * @see hid_is_apple_pro_display_xdr_device
 */
static bool hid_is_apple_pro_display_xdr_brightness_control_device(hid_device* device) {
  struct hid_report_descriptor descriptor;

  int bytes_read =
      hid_get_report_descriptor(device, (unsigned char*)&descriptor, sizeof(descriptor));

  if (bytes_read != sizeof(descriptor)) {
    fprintf(stderr,
            "error: found Apple Pro Display XDR device but failed to retrieve "
            "Report Descriptor: %ls\n",
            hid_error(device));
    return false;
  }

  return le16toh(descriptor.usage_page) == BRIGHTNESS_REPORT_PAGE &&
         le16toh(descriptor.report_usage) == BRIGHTNESS_REPORT_USAGE &&
         (le16toh(descriptor.report_id) >> 8 & 0xff) == BRIGHTNESS_REPORT_ID &&
         le16toh(descriptor.logical_minimum) == BRIGHTNESS_MIN &&
         le32toh(descriptor.logical_maximum) == BRIGHTNESS_MAX;
}

/**
 * @brief Finds and opens the Apple Pro Display XDR brightness control HID device.
 *
 * Iterates over connect HID devices and fetches the report descriptor to find the Apple Pro Display
 * XDR brightness control HID device.
 *
 * The Pro Display XDR advertises 4 HID interfaces, but only one of them is capable of brightness
 * control.
 *
 * @return The HID device if found, or NULL otherwise.
 * @see README.md
 */
static hid_device* hid_open_apple_pro_display_xdr_brightness_control_device() {
  struct hid_device_info* devices = hid_enumerate(0x0, 0x0);

  for (struct hid_device_info* it = devices; it; it = it->next) {
    if (!is_apple_pro_display_xdr_device(it)) {
      continue;
    }

    hid_device* device = hid_open_path(it->path);
    if (!device) {
      fprintf(stderr, "error: failed to open device: %s\n", it->path);
      continue;
    }
    if (!hid_is_apple_pro_display_xdr_brightness_control_device(device)) {
      hid_close(device);
      continue;
    }

    hid_free_enumeration(devices);
    return device;
  }

  hid_free_enumeration(devices);
  return NULL;
}

/**
 * @brief A HID feature report for brightness on Apple Pro Display XDR monitors.
 *
 * @param report_id The HID report ID. Must be `BRIGHTNESS_REPORT_ID`.
 * @param brightness The absolute brightness value. This value is encoded in little-endian.
 * @param padding Unused bytes.
 */
struct __attribute__((packed)) brightness_feature_report {
  uint8_t report_id;
  uint32_t brightness;
  uint16_t padding;
};

/**
 * @brief Fetches a HID feature report to get the brightness value.
 *
 * @param device[in] The HID device to fetch the report from.
 *
 * @retval >=0 The absolute brightness value.
 * @retval -1 Failed to fetch HID report.
 */
static int32_t hid_get_brightness(hid_device* device) {
  struct brightness_feature_report report = {0};
  report.report_id = BRIGHTNESS_REPORT_ID;

  if (hid_get_feature_report(device, (unsigned char*)&report, sizeof(report)) < 0) {
    fprintf(stderr, "error: failed to retrieve feature report: %ls\n", hid_error(device));
    return -1;
  }

  return le32toh(report.brightness);
}

/**
 * @brief Sends a HID feature report to update the brightness value.
 *
 * Parameter must be a valid absolute value (i.e. in [BRIGHTNESS_MIN, BRIGHTNESS_MAX]).
 *
 * @param device[in] The HID device to send the report to.
 * @param brightness[in] The absolute brightness value to request.
 *
 * @retval true HID report sent successfully.
 * @retval false Failed to send HID report.
 */
static bool hid_set_brightness(hid_device* device, uint32_t brightness) {
  assert(brightness >= BRIGHTNESS_MIN && brightness <= BRIGHTNESS_MAX);

  struct brightness_feature_report report = {0};
  report.report_id = BRIGHTNESS_REPORT_ID;
  report.brightness = htole32(brightness);

  if (hid_send_feature_report(device, (unsigned char*)&report, sizeof(report)) < 0) {
    fprintf(stderr, "error: failed to send feature report: %ls\n", hid_error(device));
    return false;
  }

  return true;
}

/**
 * @brief Converts an absolute brightness value into a percentage one.
 *
 * Parameter must be a valid absolute value (i.e. in [BRIGHTNESS_MIN, BRIGHTNESS_MAX]).
 * Floating-point values are truncated toward zero.
 *
 * @param absolute[in] The absolute value to convert to percentage.
 * @return The percentage brightness value (in [0, 100]).
 */
static uint8_t to_percent_brightness(uint32_t absolute) {
  assert(absolute >= BRIGHTNESS_MIN && absolute <= BRIGHTNESS_MAX);

  uint8_t percentage = (uint8_t)((absolute - BRIGHTNESS_MIN) / (float)BRIGHTNESS_RANGE * 100);
  assert(percentage >= 0 && percentage <= 100);

  return percentage;
}

/**
 * @brief Converts a percentage brightness value into an absolute one.
 *
 * Parameter must be a valid percentage value (i.e. in [0, 100]).
 * Floating-point values are truncated toward zero.
 *
 * @param percentage[in] The percentage value to convert to absolute.
 * @return The absolute brightness value (in [BRIGHTNESS_MIN, BRIGHTNESS_MAX]).
 */
static uint32_t to_absolute_brightness(uint8_t percentage) {
  assert(percentage >= 0 && percentage <= 100);

  uint32_t absolute = (percentage * BRIGHTNESS_RANGE / 100) + BRIGHTNESS_MIN;
  assert(absolute >= BRIGHTNESS_MIN && absolute <= BRIGHTNESS_MAX);

  return absolute;
}

/**
 * @brief Prints the current brightness value on the standard output.
 *
 * Reads the value from the HID device and formats it accordingly.
 *
 * @param as_percentage_point[in] Whether to print the value as absolute or percentage.
 *
 * @retval SUCCESS Brightness value printed successully on standard output.
 * @retval ERR_DEVICE_NOT_FOUND Apple Pro Display XDR brightness control device not found.
 * @retval ERR_HIDAPI_CALL_FAIL Failed to retrieve HID feature report.
 */
static int print_brightness(bool as_percentage_point) {
  hid_device* device = hid_open_apple_pro_display_xdr_brightness_control_device();
  if (!device) {
    fprintf(stderr, "error: Apple Pro Display XDR brightness control device not found.\n");
    return ERR_DEVICE_NOT_FOUND;
  }

  int32_t brightness = hid_get_brightness(device);
  hid_close(device);

  if (brightness < 0) {
    return ERR_HIDAPI_CALL_FAIL;
  }

  if (as_percentage_point) {
    printf("%u%%\n", to_percent_brightness(brightness));
  } else {
    printf("%u\n", brightness);
  }

  return SUCCESS;
}

/**
 * @brief Sets the brightness of the screen.
 *
 * @param value[in] The integer value of the requested brightness target.
 * @param as_percentage_point[in] Whether to interpret `value` as absolute or percentage.
 *
 * @retval SUCCESS Brightness updated successfully.
 * @retval ERR_DEVICE_NOT_FOUND Apple Pro Display XDR brightness control device not found.
 * @retval ERR_HIDAPI_CALL_FAIL Failed to send HID feature report.
 */
static int set_brightness(uint32_t value, bool as_percentage_point) {
  assert((as_percentage_point && value <= 100) ||
         (!as_percentage_point && value >= BRIGHTNESS_MIN && value <= BRIGHTNESS_MAX));

  hid_device* device = hid_open_apple_pro_display_xdr_brightness_control_device();
  if (!device) {
    fprintf(stderr, "error: Apple Pro Display XDR brightness control device not found.\n");
    return ERR_DEVICE_NOT_FOUND;
  }

  bool success =
      hid_set_brightness(device, as_percentage_point ? to_absolute_brightness(value) : value);

  hid_close(device);
  return success ? SUCCESS : ERR_HIDAPI_CALL_FAIL;
}

/**
 * @brief Parses the input string as a brightness value.
 *
 * Brightness value can be either absolute (an integer in [400, 50000]) or percentage ("50%").
 *
 * @param parameter[in] The string to parse.
 * @param value[out] The output value, if successful.
 * @param as_percentage_point[out] Whether `value` is absolute or percentage.
 *
 * @retval true Parsing successful.
 * @retval false Malformed absolute or percentage brightness value.
 */
static bool parse_brightness_parameter(const char* parameter, uint32_t* value,
                                       bool* as_percentage_point) {
  char* last = NULL;

  errno = 0;
  unsigned long parsed = strtoul(parameter, &last, /* base= */ 10);

  if (parsed == ULONG_MAX && errno) {
    return false;
  }

  // No digits found.
  if (parameter == last) return false;

  if (*last == '%' && *(last + 1) == '\0' && parsed <= 100) {
    *value = parsed;
    *as_percentage_point = true;
    return true;
  }

  if (*last == '\0' && parsed >= BRIGHTNESS_MIN && parsed <= BRIGHTNESS_MAX) {
    *value = parsed;
    *as_percentage_point = false;
    return true;
  }

  // Any other trailing character.
  return false;
}

int main(int argc, char* argv[]) {
  // Fail if API version majors differ. Better safe than sending the wrong command to the device.
  if (HID_API_VERSION_MAJOR != hid_version()->major) {
    fprintf(stderr, "This program was built with a different version of hidapi.\n");
    return ERR_INVALID_PRECONDITION;
  }

  if (argc < 2 || argc > 3) {
    fprintf(stderr, "error: invalid parameters\n");
    print_usage(argv[0]);
    return ERR_INVALID_ARGUMENT;
  }

  if (argc == 2 &&
      (!strcmp(argv[1], "--help") || !strcmp(argv[1], "-h") || !strcmp(argv[1], "help"))) {
    print_usage(argv[0]);
    return SUCCESS;
  }

  // <program> get [-%]
  if (!strcmp(argv[1], "get")) {
    if (argc == 3 && strcmp(argv[2], "-%") && strcmp(argv[2], "-p") &&
        strcmp(argv[2], "--percent")) {
      fprintf(stderr, "error: unknown parameter '-%%' for command 'get'.\n");
      print_usage(argv[0]);
      return ERR_INVALID_ARGUMENT;
    }
    bool as_percentage_point = argc == 3;
    return print_brightness(as_percentage_point);
  }

  // <program> set <value>
  if (!strcmp(argv[1], "set")) {
    if (argc < 3) {
      fprintf(stderr, "error: 'set' command requires a value argument.\n");
      print_usage(argv[0]);
      return ERR_INVALID_ARGUMENT;
    }

    uint32_t brightness;
    bool as_percentage_point;

    if (!parse_brightness_parameter(argv[2], &brightness, &as_percentage_point)) {
      fprintf(stderr,
              "error: invalid brightness value '%s'. Must be a valid integer (in [%u, %u]) or "
              "percentage [0%%, 100%%].\n",
              argv[2], BRIGHTNESS_MIN, BRIGHTNESS_MAX);
      return ERR_INVALID_ARGUMENT;
    }

    return set_brightness(brightness, as_percentage_point);
  }

  fprintf(stderr, "error: unknown command '%s'\n", argv[1]);
  print_usage(argv[0]);
  return ERR_INVALID_ARGUMENT;
}
