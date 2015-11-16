require 'pe_build/util/version_string'

# Configuration for PE Agent provisioners
#
# @since 0.13.0
class PEBuild::Config::PEAgent < Vagrant.plugin('2', :config)
  # The minimum PE Version supported by this provisioner.
  MINIMUM_VERSION    = '2015.2.0'

  # @!attribute [rw] autosign
  #   If true, and {#master_vm} is set, the agent's certificate will be signed
  #   on the master VM. DNS alternative names will be approved, if present.
  #
  #   @return [true, false] Defaults to `true` if {#master_vm} is set,
  #     otherwise `false`.
  attr_accessor :autosign

  # @!attribute [rw] autopurge
  #   If true, and {#master_vm} is set, the agent's certificate and data will
  #   be purged from the master VM if the agent is destroyed by Vagrant.
  #
  #   @return [true, false] Defaults to `true` if {#master_vm} is set,
  #     otherwise `false`.
  attr_accessor :autopurge

  # @!attribute [rw] install_options
  #   A hash that maps settings to values that will be passed to the installer.
  #
  #   @return [Hash{String => Hash{String => String}}] A hash that maps
  #     puppet.conf section to hashes of settings and values. These will
  #     be passed to the install script as options of the form:
  #
  #         <section>:<setting>=<value>
  attr_accessor :install_options

  # @!attribute master
  #   @return [String] The DNS hostname of the Puppet master for this node.
  #     If {#master_vm} is set, the hostname of that machine will be used
  #     as a default. If the hostname is unset, the name of the VM will be
  #     used as a secondary default.
  attr_accessor :master

  # @!attribute master_vm
  #   @return [String] The name of a Vagrant VM to use as the master.
  attr_accessor :master_vm

  # @!attribute version
  #   @return [String] The version of PE to install. May be either a version
  #   string of the form `x.y.x[-optional-arbitrary-stuff]` or the string
  #   `current`. Defaults to `current`.
  attr_accessor :version

  def initialize
    @autosign      = UNSET_VALUE
    @autopurge     = UNSET_VALUE
    @install_options = {}
    @master        = UNSET_VALUE
    @master_vm     = UNSET_VALUE
    @version       = UNSET_VALUE
  end

  def finalize!
    @master        = nil if @master == UNSET_VALUE
    @master_vm     = nil if @master_vm == UNSET_VALUE
    @autosign      = (not @master_vm.nil?) if @autosign  == UNSET_VALUE
    @autopurge     = (not @master_vm.nil?) if @autopurge == UNSET_VALUE
    @version       = 'current' if @version == UNSET_VALUE
  end

  # Lookup a install_option setting by section
  #
  # @param setting [String, Symbol] The name of the setting.
  # @param section [String, Symbol] The section to search before `:main`.
  #
  # @return [Object] The value of the setting if found in the given section.
  # @return [nil] A `nil` value, if the setting was not found.
  def setting(section, setting)
    setting = setting.to_sym
    section = section.to_sym

    # Sanitize the hash such that all keys are Symbols. This simplifies
    # searching for particular keys.
    symbolize_keys = lambda do |hash|
      hash.inject({}) do |symbolized, (k,v)|
        symbolized[k.intern] = (v.is_a?(Hash) ? symbolize_keys.call(v) : v)
        symbolized
      end
    end
    options = symbolize_keys.call(@install_options)

    options.fetch(section, {}).fetch(setting, nil)
  end

  def validate(machine)
    errors = _detected_errors

    if @master.nil? && @master_vm.nil?
      errors << I18n.t('pebuild.config.pe_agent.errors.no_master')
    end

    validate_master_vm!(errors, machine)
    validate_version!(errors, machine)
    # TODO: Install options can't be set on a Linux machine using PE < 3.7
    validate_install_options!(errors, machine)

    {'pe_agent provisioner' => errors}
  end

  private

  def validate_master_vm!(errors, machine)
    if (not @master_vm.nil?) && (not machine.env.machine_names.include?(@master_vm.intern))
      errors << I18n.t(
        'pebuild.config.pe_agent.errors.master_vm_not_defined',
        :vm_name  => @master_vm
      )
    end

    if @autosign && @master_vm.nil?
      errors << I18n.t(
        'pebuild.config.pe_agent.errors.master_vm_required',
        :setting  => 'autosign'
      )
    end

    if @autopurge && @master_vm.nil?
      errors << I18n.t(
        'pebuild.config.pe_agent.errors.master_vm_required',
        :setting  => 'autopurge'
      )
    end
  end

  def validate_version!(errors, machine)
    pe_version_regex = %r[\d+\.\d+\.\d+[\w-]*]

    if @version.kind_of? String
      return if version == 'current'
      if version.match(pe_version_regex)
        unless PEBuild::Util::VersionString.compare(@version, MINIMUM_VERSION) >= 0
          errors << I18n.t(
            'pebuild.config.pe_agent.errors.version_too_old',
            :version         => @version,
            :minimum_version => MINIMUM_VERSION
          )
        end

        return
      end
    end

    # If we end up here, the version was not a string that matched 'current' or
    # the regex. Mutate the error array.
    errors << I18n.t(
      'pebuild.config.pe_agent.errors.malformed_version',
      :version       => @version,
      :version_class => @version.class
    )
  end

  def validate_install_options!(errors, machine)
    unless @install_options.is_a?(Hash)
      errors << I18n.t(
        'pebuild.config.pe_agent.errors.install_options_must_be_hash',
        :options_class => @install_options.class
      )
      return
    end

    @install_options.each do |section, settings|
      unless settings.is_a?(Hash)
        errors << I18n.t(
          'pebuild.config.pe_agent.errors.install_options_settings_must_be_hash',
          :section        => section,
          :settings_class => settings.class
        )
      end
    end
  end
end
