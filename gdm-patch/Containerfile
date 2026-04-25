FROM ghcr.io/ublue-os/bazzite-deck-gnome:stable

# ── COSA FA QUESTO FILE ───────────────────────────────────────────────────────
#
# Parte da bazzite-deck-gnome e:
#  1. Rimuove il bloatware
#  2. Ripristina pacchetti Silverblue rimossi da Bazzite
#  3. Rimuove Homebrew
#  4. Rimuove tutto ciò che riguarda SDDM e i servizi disabilitati
#  5. Sostituisce SDDM con GDM (display manager nativo di GNOME)
#  6. Ripristina il branding Fedora Linux

# ── 1. RIMOZIONE PACCHETTI BLOATWARE ─────────────────────────────────────────
RUN rpm-ostree override remove \
        lutris \
        waydroid \
        vkBasalt \
        mangohud \
        libobs_vkcapture \
        libobs_glcapture \
        umu-launcher \
        distrobox \
    2>/dev/null || true

# ── 2. RIPRISTINO PACCHETTI RIMOSSI DA BAZZITE ───────────────────────────────
RUN rpm-ostree install \
        firefox \
        firefox-langpacks \
        gnome-software \
        toolbox \
        gnome-tour \
        htop

# ── 3. RIMOZIONE HOMEBREW ─────────────────────────────────────────────────────
# Bazzite include Homebrew (brew) preinstallato con relativi
# servizi, script e file di configurazione.
RUN \
    # Rimuovi il servizio brew-setup
    systemctl disable brew-setup.service 2>/dev/null || true && \
    rm -f /usr/lib/systemd/system/brew-setup.service && \
    rm -f /usr/lib/systemd/system/brew-setup-user.service && \
    # Rimuovi i binari e script brew
    rm -f /usr/bin/brew \
          /usr/bin/bbrew \
          /usr/bin/bbrew-helper && \
    # Rimuovi le applicazioni desktop di brew
    rm -f /usr/share/applications/bbrew.desktop && \
    # Rimuovi le icone brew
    rm -f /usr/share/pixmaps/homebrew.png \
          /usr/share/ublue-os/bbrew.png && \
    # Rimuovi i file di configurazione brew
    rm -rf /etc/homebrew \
           /home/linuxbrew \
           /var/home/linuxbrew 2>/dev/null || true && \
    # Rimuovi profile.d che imposta PATH brew
    rm -f /etc/profile.d/homebrew.sh \
          /etc/profile.d/brew.sh

# ── 4. RIMOZIONE FILE SDDM E bazzite-flatpak-manager ────────────────────────

RUN \
    # SDDM: rimuovi configurazioni, temi e pacchetto
    rpm-ostree override remove sddm 2>/dev/null || true && \
    rm -rf /etc/sddm.conf \
           /etc/sddm.conf.d \
           /usr/share/sddm \
           /usr/lib/sddm && \
    # Disabilita e rimuovi bazzite-flatpak-manager
    systemctl disable bazzite-flatpak-manager.service 2>/dev/null || true && \
    rm -f /usr/lib/systemd/system/bazzite-flatpak-manager.service

# ── 5. SWITCH DA SDDM A GDM ──────────────────────────────────────────────────
# Copia gli script patchati per GDM e configura il sistema.
# I file in gdm-patch/ sostituiscono steamos-session-select,
# return-to-gamemode e bazzite-autologin con versioni che
# scrivono in /etc/gdm/custom.conf invece di /etc/sddm.conf.d/.

COPY gdm-patch/ /

RUN \
    chmod +x /usr/bin/steamos-session-select \
              /usr/bin/return-to-gamemode \
              /usr/bin/bazzite-autologin && \
    # Abilita GDM (SDDM era già disabilitato/rimosso sopra)
    systemctl enable gdm.service && \
    # Workaround: crea gnome-initial-setup-done nello skel
    # così ogni nuovo utente lo ha già (necessario per GDM autologin)
    mkdir -p /etc/skel/.config && \
    touch /etc/skel/.config/gnome-initial-setup-done

# ── 6. RIPRISTINO BRANDING FEDORA ────────────────────────────────────────────
RUN \
    sed -i 's/^NAME=.*/NAME="Fedora Linux"/' /usr/lib/os-release && \
    sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Fedora Linux (GNOME)"/' /usr/lib/os-release && \
    sed -i 's/^HOME_URL=.*/HOME_URL="https:\/\/fedoraproject.org\/"/' /usr/lib/os-release && \
    sed -i 's/^SUPPORT_URL=.*/SUPPORT_URL="https:\/\/ask.fedoraproject.org\/"/' /usr/lib/os-release && \
    sed -i 's/^BUG_REPORT_URL=.*/BUG_REPORT_URL="https:\/\/bugzilla.redhat.com\/"/' /usr/lib/os-release && \
    sed -i 's/^DOCUMENTATION_URL=.*/DOCUMENTATION_URL="https:\/\/docs.fedoraproject.org\/en-US\/fedora\/latest\/"/' /usr/lib/os-release && \
    sed -i '/^LOGO=.*bazzite/Id' /usr/lib/os-release && \
    sed -i '/^DEFAULT_HOSTNAME=.*bazzite/Id' /usr/lib/os-release && \
    sed -i '/^BOOTLOADER_NAME=.*Bazzite/d' /usr/lib/os-release && \
    sed -i '/^BUILD_ID=.*Bazzite/d' /usr/lib/os-release && \
    sed -i '/^CPE_NAME=.*bazzite/Id' /usr/lib/os-release && \
    rm -f /usr/share/plymouth/themes/spinner/watermark.png && \
    rm -f /usr/share/fish/functions/fish_greeting.fish && \
    rm -f /usr/share/icons/hicolor/scalable/places/bazzite-logo-le.svg && \
    rm -f /etc/dconf/db/distro.d/01-bazzite-desktop-silverblue-folders && \
    rm -f /usr/share/glib-2.0/schemas/zz0-01-bazzite-desktop-silverblue-dash.gschema.override && \
    glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null

RUN ostree container commit
