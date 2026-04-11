#include "mtp_picker.h"

#include <windows.h>
#include <shobjidl.h>   // IFileOpenDialog
#include <shlobj.h>
#include <string>
#include <optional>

#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <flutter/binary_messenger.h>

namespace mtp_picker {

// Coba ambil filesystem path dari IShellItem
static std::optional<std::string> GetPathFromShellItem(IShellItem* item) {
  // Coba SIGDN_FILESYSPATH dulu (local disk)
  PWSTR pszPath = nullptr;
  HRESULT hr = item->GetDisplayName(SIGDN_FILESYSPATH, &pszPath);
  if (SUCCEEDED(hr) && pszPath) {
    int len = WideCharToMultiByte(CP_UTF8, 0, pszPath, -1, nullptr, 0, nullptr, nullptr);
    std::string result(len - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, pszPath, -1, result.data(), len, nullptr, nullptr);
    CoTaskMemFree(pszPath);
    return result;
  }

  // Fallback: SIGDN_DESKTOPABSOLUTEPARSING (bisa dapat parsing name untuk MTP)
  hr = item->GetDisplayName(SIGDN_DESKTOPABSOLUTEPARSING, &pszPath);
  if (SUCCEEDED(hr) && pszPath) {
    int len = WideCharToMultiByte(CP_UTF8, 0, pszPath, -1, nullptr, 0, nullptr, nullptr);
    std::string result(len - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, pszPath, -1, result.data(), len, nullptr, nullptr);
    CoTaskMemFree(pszPath);
    // Kembalikan parsing name (dipakai Dart untuk enumerate via Shell)
    return result;
  }

  return std::nullopt;
}

static std::optional<std::string> PickFolder(HWND parent) {
  HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  bool needUninit = SUCCEEDED(hr);

  std::optional<std::string> result;

  IFileOpenDialog* pfd = nullptr;
  hr = CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_INPROC_SERVER,
                        IID_PPV_ARGS(&pfd));
  if (FAILED(hr)) {
    if (needUninit) CoUninitialize();
    return std::nullopt;
  }

  // Set options: pick folder, don't require filesystem path
  DWORD dwOptions = 0;
  pfd->GetOptions(&dwOptions);
  pfd->SetOptions(dwOptions
    | FOS_PICKFOLDERS       // mode pilih folder
  );

  // Set title
  pfd->SetTitle(L"Pilih folder foto");

  // Tampilkan dialog
  hr = pfd->Show(parent);
  if (SUCCEEDED(hr)) {
    IShellItem* psi = nullptr;
    hr = pfd->GetResult(&psi);
    if (SUCCEEDED(hr) && psi) {
      result = GetPathFromShellItem(psi);
      psi->Release();
    }
  }

  pfd->Release();
  if (needUninit) CoUninitialize();
  return result;
}

void RegisterWithMessenger(flutter::BinaryMessenger* messenger) {
  auto channel = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger,
      "sweepe/mtp_picker",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [channel](const flutter::MethodCall<flutter::EncodableValue>& call,
                std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "pickFolder") {
          auto path = PickFolder(nullptr);
          if (path.has_value()) {
            result->Success(flutter::EncodableValue(path.value()));
          } else {
            result->Success(flutter::EncodableValue()); // null = cancelled
          }
        } else {
          result->NotImplemented();
        }
      });
}

} // namespace mtp_picker
