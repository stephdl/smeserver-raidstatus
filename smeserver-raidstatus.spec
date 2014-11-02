Summary: SME server Raidstatus
%define name smeserver-raidstatus
Name: %{name}
%define version 0.3
%define release 2 
Version: %{version}
Release: %{release}%{?dist}
License: SWT
Group: Administration
Source: %{name}-%{version}.tar.gz
Packager: Walter Thoss <Support@swt-online.de>
BuildRoot: /var/tmp/e-smith-buildroot
BuildRequires: e-smith-devtools
BuildArchitectures: noarch
Requires: e-smith-release >= 8.0
AutoReqProv: no

%changelog
* Sun Nov 2 2014 Stephane de Labrusse <stephdl@de-labrusse.fr> 0.3-2
- Removed the test of md0 for sme8

* Thu Aug 14 2014 Stephane de Labrusse <stephdl@de-labrusse.fr> 0.3-1
- Added 'mailto' db setting in the server-manager panel

* Thu Jun 05 2014 Stephane de Labrusse <stephdl@de-labrusse.fr> 0.2-1
- unitialised value $2
* Sat Mar 15 2014 Stephane de Labrusse <stephdl@de-labrusse.fr> 0.1.8
- a great big thank to walter who have made the new design and corrected a bug i made
- back of my weekly mail status
* Mon Feb 24 2014 Walter Thoss <Support@swt-online.de>  0.1.6
- design and change to smeserver standard
* Wed Feb 05 2014 Stephane de Labrusse <stephdl@de-labrusse.fr>  0.1
- First release

%description
Display raid status in server-manager

%prep
%setup

%build
perl createlinks

%install
rm -rf $RPM_BUILD_ROOT
(cd root   ; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
rm -f %{name}-%{version}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT > %{name}-%{version}-filelist


%clean
rm -rf $RPM_BUILD_ROOT

%pre

%preun

%post
#echo "Rebuilding Server Manager Panel."
#/etc/e-smith/events/actions/navigation-conf >/dev/null 2>&1
#echo "Done."

%postun

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
