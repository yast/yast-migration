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

require "yast"

module Migration
  # Check for possible repository issues in the libzypp products
  class RepositoryChecker
    include Yast::Logger

    # constructor
    # @param [Array<Hash>] products list of products from pkg-bindings
    def initialize(products)
      @products = products
    end

    # get list of repositories which provide an obsolete product
    # (an upgrade is available for them)
    # return [Array<Fixnum>] repositories providing obsolete products
    def obsolete_product_repos
      old_repos = obsolete_available_products.map { |product| product["source"] }

      # remove (possible) duplicates
      old_repos.uniq!

      log.info "Found obsolete repositories: #{old_repos}"
      old_repos
    end

    private

    attr_accessor :products

    # get the available obsolete products
    # @return [Array<Hash>] obsolete products
    def obsolete_available_products
      obsolete_products = []

      # available or to be installed products
      available_products = select_products(:available) + select_products(:selected)

      available_products.each do |available_product|
        available_products.each do |product|
          if product_upgrade?(available_product, product)
            obsolete_products << product
          end
        end
      end

      obsolete_products
    end

    # select the products with the specified status
    # @param [Symbol] status required status of the products
    # @return [Array<Hash>] list of libzypp products
    def select_products(status)
      products.select { |product| product["status"] == status }
    end

    # Does a product upgrade another product?
    # @param [Hash] new_product new product
    # @param [Hash] old_product old product
    # @return [Boolean] true if the new product upgrades the old product
    def product_upgrade?(new_product, old_product)
      # use Gem::Version internally for a proper version string comparison
      # TODO: check also "provides" to handle product renames (should not happen
      # in SP migration, but anyway...)
      old_product["name"] == new_product["name"] &&
        (Gem::Version.new(old_product["version_version"]) <
          Gem::Version.new(new_product["version_version"]))
    end
  end
end
