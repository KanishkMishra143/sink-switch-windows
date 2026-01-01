Name:           sink-switch
Version:        1.0
Release:        1%{?dist}
Summary:        Simple audio sink switcher for PulseAudio/PipeWire

License:        MIT
URL:            https://github.com/KanishkMishra143/sink-switch
Source0:        https://github.com/KanishkMishra143/sink-switch/archive/refs/tags/v1.0.tar.gz

BuildArch:      noarch
Requires:       bash, pulseaudio-utils, libnotify

%description
A simple Bash script to switch between available audio output sinks dynamically using pactl.
Supports notifications, cycling, setting by name, and more.

%prep
%setup -q

%build
# Nothing to build

%install
mkdir -p %{buildroot}%{_bindir}
install -m 0755 sink-switch.sh %{buildroot}%{_bindir}/sink-switch

%files
%license LICENSE
%doc README.md
%{_bindir}/sink-switch

%changelog
* Thu Jun 26 2025 Kanishk Mishra <kanishk.mishra012@adgitmdelhi.ac.in> - 1.0-1
- Initial COPR release
