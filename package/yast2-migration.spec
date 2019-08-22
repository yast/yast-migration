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

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#


Name:           yast2-migration
Version:        4.2.2
Release:        0
Summary:        YaST2 - Online migration
Group:          System/YaST
License:        GPL-2.0
Url:            https://github.com/yast/yast-migration

Source0:        %{name}-%{version}.tar.bz2

BuildRequires:  yast2-buildtools >= 4.2.2
BuildRequires:  yast2 >= 3.1.130
BuildRequires:  rubygem( %{rb_default_ruby_abi}:rspec)
BuildRequires:  rubygem( %{rb_default_ruby_abi}:yast-rake)
BuildRequires:  yast2-packager
BuildRequires:  yast2-ruby-bindings
# needed in build for testing
BuildRequires:  yast2-installation >= 3.1.137
BuildRequires:  yast2-update
BuildRequires:  update-desktop-files

Requires:       yast2 >= 3.1.130
Requires:       yast2-packager
Requires:       yast2-pkg-bindings
Requires:       yast2-ruby-bindings
# new rollback client
Requires:       yast2-registration >= 3.1.153
# need recent enough installation for working proposal runner
Requires:       yast2-installation >= 3.1.146
Requires:       yast2-update

Supplements:    yast2-registration

BuildArch: noarch

%description
This package contains the YaST2 component for online migration.

%prep
%setup -q

%check
%yast_check

%build

%install
%yast_install
%yast_metainfo

%files
%{yast_clientdir}
%{yast_libdir}
%{yast_desktopdir}
%{yast_metainfodir}
%{yast_icondir}
%license COPYING
%doc %{yast_docdir}

%changelog
