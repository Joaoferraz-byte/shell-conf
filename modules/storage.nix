{ ... }:

{
  # Nautilus is only a client; udiskie performs automounting in the
  # user session through the system udisks2 D-Bus service.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = false;
    tray = "never";
  };
}
