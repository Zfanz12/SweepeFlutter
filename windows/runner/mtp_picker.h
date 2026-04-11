#pragma once

#include <flutter/binary_messenger.h>
#include <windows.h>

namespace mtp_picker {
void RegisterWithMessenger(flutter::BinaryMessenger* messenger);
} // namespace mtp_picker
