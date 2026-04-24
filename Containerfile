# ============================================================
#  Custom Fedora Silverblue 44 — Steam Deck (GNOME)
#
#  Basato su Fedora Silverblue ufficiale, senza fork di Bazzite.
#  Aggiunge solo ciò che serve per lo Steam Deck:
#    - kernel e Mesa patchati Valve (dal COPR ublue-os/bazzite)
#    - hardware support (hhd, jupiter-fan-control, steamdeck-dsp, ecc.)
#    - gamescope-session per la Gaming Mode
#    - Steam
#  Rimuove: firefox, toolbox e altri pacchetti non necessari.
#  Branding: Fedora Linux invariato.
# ============================================================

FROM quay.io/fedora/fedora-silverblue:43

# ── RIMOZIONE PACCHETTI NON VOLUTI ───────────────────────────────────────────
RUN dnf5 -y remove \
        firefox \
        firefox-langpacks \
        #toolbox \
        gnome-tour \
        #gnome-classic-session \
        #gnome-extensions-app \
        gnome-initial-setup \
        #gnome-shell-extension-background-logo \
        #gnome-shell-extension-apps-menu \
        #gnome-shell-extension-launch-new-instance \
        #gnome-shell-extension-places-menu \
        #gnome-shell-extension-window-list \
        && \
    dnf5 clean all

# ── REPOSITORY AGGIUNTIVI ────────────────────────────────────────────────────
RUN dnf5 -y install dnf5-plugins && \
    # RPM Fusion (codec, steam)
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    # COPR Bazzite: kernel patchato Valve, Mesa patchata, UPower patchato,
    #               hhd, gamescope-session, jupiter-hw-support, steamdeck-dsp
    dnf5 -y copr enable ublue-os/bazzite && \
    dnf5 -y copr enable ublue-os/bazzite-multilib && \
    dnf5 -y copr enable ublue-os/hhd && \
    dnf5 -y copr enable ublue-os/packages && \
    dnf5 clean all

# ── KERNEL PATCHATO VALVE ────────────────────────────────────────────────────
# Il kernel Bazzite include: fsync, HDR, fix specifici Steam Deck
# Sostituisce il kernel Fedora stock con quello dal COPR bazzite-org
#
# NOTA: se il COPR non ha ancora F44, rimuovi questo blocco e usa il
#       kernel Fedora stock — tutto il resto funzionerà lo stesso.
#RUN dnf5 -y swap \
#        --repo copr:copr.fedorainfracloud.org:ublue-os:bazzite \
#        kernel-core kernel-core && \
#    dnf5 clean all

# ── MESA E STACK AUDIO/BLUETOOTH PATCHATI VALVE ──────────────────────────────
# Valve patcha Mesa, Pipewire, Bluez e Xwayland per ottimizzazioni Steam Deck
RUN dnf5 -y remove \
        mesa-va-drivers \
        pipewire-config-raop && \
    dnf5 -y swap \
        --repo copr:copr.fedorainfracloud.org:ublue-os:bazzite \
        wireplumber wireplumber && \
    dnf5 -y swap \
        --repo copr:copr.fedorainfracloud.org:ublue-os:bazzite-multilib \
        pipewire pipewire && \
    dnf5 -y swap \
        --repo copr:copr.fedorainfracloud.org:ublue-os:bazzite-multilib \
        bluez bluez && \
    dnf5 -y swap \
        --repo copr:copr.fedorainfracloud.org:ublue-os:bazzite-multilib \
        xorg-x11-server-Xwayland xorg-x11-server-Xwayland && \
    dnf5 -y swap \
        --repo copr:copr.fedorainfracloud.org:ublue-os:bazzite-multilib \
        mutter mutter && \
    dnf5 -y swap \
        --repo copr:copr.fedorainfracloud.org:ublue-os:bazzite-multilib \
        gnome-shell gnome-shell && \
    dnf5 versionlock add \
        pipewire pipewire-libs pipewire-alsa pipewire-pulseaudio \
        wireplumber wireplumber-libs \
        bluez bluez-libs \
        xorg-x11-server-Xwayland \
        mutter gnome-shell && \
    dnf5 clean all

# ── UPOWER PATCHATO VALVE ────────────────────────────────────────────────────
# Necessario per la corretta gestione della batteria dello Steam Deck
RUN dnf5 -y swap \
        --repo copr:copr.fedorainfracloud.org:ublue-os:bazzite \
        upower upower && \
    dnf5 versionlock add upower upower-libs && \
    dnf5 clean all

# ── STEAM ─────────────────────────────────────────────────────────────────────
RUN dnf5 -y install \
        steam \
        gamescope \
        #gamescope-libs \
        gamescope-shaders \
        #dbus-x11 \
        #xrandr \
        #libFAudio \
        xdg-user-dirs \
        #winetricks \
        && \
    dnf5 clean all

# ── HARDWARE STEAM DECK ───────────────────────────────────────────────────────
# jupiter-fan-control  → ventole
# jupiter-hw-support   → firmware e tool Valve
# steamdeck-dsp        → audio specifico del deck
# hhd + hhd-ui         → input controller, gyroscopio, gamepad emulation
# steamos-manager      → gestione sessioni Gaming/Desktop
# powerbuttond         → gestione tasto power
# vpower               → gestione TDP
# steam_notif_daemon   → notifiche Steam in Gaming Mode
# sdgyrodsu            → gyroscopio DSU (disabilitato di default, opt-in)
# acpica-tools         → tool ACPI necessari per alcuni fix hardware
RUN dnf5 -y install \
        jupiter-fan-control \
        jupiter-hw-support-btrfs \
        #steamdeck-dsp \
        powerbuttond \
        hhd \
        hhd-ui \
        steamos-manager \
        vpower \
        steam_notif_daemon \
        sdgyrodsu \
        acpica-tools && \
    dnf5 clean all

# ── SDDM (necessario per Gaming Mode) ────────────────────────────────────────
# La Gaming Mode (gamescope-session) usa SDDM, non GDM
RUN dnf5 -y install sddm qt6-qtvirtualkeyboard && \
    systemctl disable gdm.service && \
    systemctl enable sddm.service && \
    dnf5 clean all

# ── GAMESCOPE SESSION (Gaming Mode) ──────────────────────────────────────────
RUN dnf5 -y install \
        --repo copr:copr.fedorainfracloud.org:ublue-os:bazzite \
        gamescope-session-plus \
        gamescope-session-steam && \
    mkdir -p /usr/share/gamescope-session-plus/ && \
    curl --retry 3 -Lo /usr/share/gamescope-session-plus/bootstrap_steam.tar.gz \
        https://large-package-sources.nobaraproject.org/bootstrap_steam.tar.gz && \
    dnf5 clean all

# ── UTILITÀ MINIME ────────────────────────────────────────────────────────────
RUN dnf5 -y install \
        flatpak \
        #fish \
        #btop \
        #vim \
        #fastfetch \
        p7zip \
        p7zip-plugins \
        vulkan-tools \
        ddcutil \
        i2c-tools \
        lm_sensors \
        iio-sensor-proxy \
        ryzenadj \
        snapper \
        btrfs-assistant \
        #google-noto-sans-cjk-fonts \
        dejavu-sans-mono-fonts \
        gnome-tweaks \
        && \
    dnf5 clean all

# ── FLATHUB ──────────────────────────────────────────────────────────────────
RUN mkdir -p /etc/flatpak/remotes.d && \
    curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo \
        https://dl.flathub.org/repo/flathub.flatpakrepo

# ── SERVIZI ───────────────────────────────────────────────────────────────────
RUN systemctl enable hhd.service && \
    systemctl enable --global steamos-manager.service && \
    #systemctl enable bazzite-autologin.service && \
    systemctl disable jupiter-fan-control.service && \
    systemctl disable vpower.service && \
    systemctl disable jupiter-biosupdate.service && \
    systemctl disable jupiter-controller-update.service && \
    systemctl --global disable sdgyrodsu.service

# ── DISABILITA COPR DOPO IL BUILD ────────────────────────────────────────────
RUN dnf5 -y copr disable ublue-os/bazzite && \
    dnf5 -y copr disable ublue-os/bazzite-multilib && \
    dnf5 -y copr disable ublue-os/hhd && \
    dnf5 -y copr disable ublue-os/packages && \
    dnf5 clean all

# ── VERIFICA FINALE ───────────────────────────────────────────────────────────
RUN bootc container lint
