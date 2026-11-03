{ config, ... }:
let
  location = config.networking.hostName;
in
{
  # Match the DUT SSDs, never the workstation's OS disk.
  services.udev.extraRules = ''
    SUBSYSTEM=="block", KERNEL=="sd[a-z]", ENV{ID_SERIAL_SHORT}=="REPLACE_WITH_X1_SSD_SERIAL", SYMLINK+="testagent-lenovo-x1-ssd", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="block", KERNEL=="sd[a-z]", ENV{ID_SERIAL_SHORT}=="REPLACE_WITH_DARTER_SSD_SERIAL", SYMLINK+="testagent-darter-pro-ssd", MODE="0660", GROUP="dialout"
  '';

  # Robot names must match the shared pipeline library's device catalog.
  services.testagent.testConfig.addresses = {
    relay_serial_port = "NONE";
    LenovoX1-1 = {
      inherit location;
      device_id = "REPLACE_WITH_X1_DEVICE_ID";
      netvm_hostname = "REPLACE_WITH_X1_NETVM_HOSTNAME";
      device_ip_address = "192.0.2.53";
      ext_drive_by-id = "/dev/testagent-lenovo-x1-ssd";
      serial_port = "NONE";
      socket_ip_address = "NONE";
      plug_type = "NONE";
      switch_bot = "REPLACE_WITH_X1_SWITCHBOT";
      usbhub_serial = "REPLACE_WITH_X1_USB_HUB_SERIAL";
      threads = 20;
    };
    DarterPRO = {
      inherit location;
      device_id = "REPLACE_WITH_DARTER_DEVICE_ID";
      netvm_hostname = "REPLACE_WITH_DARTER_NETVM_HOSTNAME";
      device_ip_address = "192.0.2.54";
      ext_drive_by-id = "/dev/testagent-darter-pro-ssd";
      serial_port = "NONE";
      socket_ip_address = "NONE";
      plug_type = "NONE";
      switch_bot = "REPLACE_WITH_DARTER_SWITCHBOT";
      usbhub_serial = "REPLACE_WITH_DARTER_USB_HUB_SERIAL";
      threads = 16;
    };
  };
}
