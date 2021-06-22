#
# spec file for package yast2-migration
#
# Copyright (c) 2015 SUSE LLC, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-migration
Version:        4.1.3
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0
Url:            http://github.com/yast/yast-migration
BuildRequires:	yast2-buildtools
BuildRequires:	yast2 >= 3.1.130
BuildRequires:  rubygem(rspec)
BuildRequires:  rubygem(yast-rake)
BuildRequires:  yast2-packager
BuildRequires:  yast2-ruby-bindings
# needed in build for testing
BuildRequires:  yast2-installation >= 3.1.137
BuildRequires:  yast2-update
Requires:	yast2 >= 3.1.130
Requires:	yast2-packager
Requires:	yast2-pkg-bindings
Requires:       yast2-ruby-bindings
# new rollback client
Requires:       yast2-registration >= 3.1.153
# need recent enough installation for working proposal runner
Requires:       yast2-installation >= 3.1.146
Requires:       yast2-update
Supplements:    yast2-registration

BuildArch: noarch

Summary:	YaST2 - Online migration

%description
This package contains the YaST2 component for online migration.

%prep
%setup -n %{name}-%{version}

%check
rake test:unit

%build

%install
rake install DESTDIR="%{buildroot}"

%files
%defattr(-,root,root)
%{yast_clientdir}/*.rb
%{yast_libdir}/migration
%{yast_desktopdir}/*.desktop
%{yast_icondir}

%dir %{yast_docdir}
%license COPYING
%doc %{yast_docdir}/README.md
%doc %{yast_docdir}/CONTRIBUTING.md
