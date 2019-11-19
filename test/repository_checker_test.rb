# ------------------------------------------------------------------------------
# Copyright (c) 2015 SUSE LLC, All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require_relative "test_helper"

require "migration/repository_checker"

describe Migration::RepositoryChecker do
  subject do
    Y2Packager::Resolvable.new
    products = load_yaml_data("sles12_migration_products.yml").map do |p|
      Y2Packager::Resolvable.new(p)
    end
    Migration::RepositoryChecker.new(products)
  end

  describe "#obsolete_product_repos" do
    it "returns repositories containing obsolete products" do
      expect(subject.obsolete_product_repos).to eq([0])
    end
  end
end
