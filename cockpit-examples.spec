%if "%{!?releasever:1}"
%define releasever 0
%endif

Name:		cockpit-examples
Version:	%{releasever}
Release:	1%{?dist}
Summary:	Cockpit API Examples

License:	LGPL-2.1+
URL:		https://github.com/cockpit-project/cockpit-examples
Source0:	cockpit-examples-%{version}.tar.xz
BuildArch:	noarch

Requires:	cockpit-bridge >= 138

%description
Examples how to use the Cockpit API to create your own Cockpit pages.

%prep
%setup -q

%build

%install
%make_install
(cd %{buildroot}; find -type f) | sed 's|^\.||' > files.list

%files -f files.list

%changelog

