require 'active_model'

module Services
  class ChangesTracker
    include ActiveModel::Dirty
    include ActiveModel::AttributeMethods

    DIRTY_VARIABLES = %w[@mutations_from_database @attributes_changed_by_setter].freeze

    def initialize(object, attrs_list = [])
      initialize_attributes(object, attrs_list)
    end

    def to_hash
      variables = exclude_items_from_list(DIRTY_VARIABLES, instance_variables)
      Hash[map_instance_variables_to_values_array(variables)]
    end

    private

    def initialize_attributes(object, attrs_list = [])
      object_attributes = object_attributes_list(object, attrs_list)
      object_attributes.each do |attr|
        build_method(attr)
        if object.is_a?(Hash) || object.is_a?(HashWithIndifferentAccess)
          instance_variable_set("@#{attr}", object[attr])
        else
          instance_variable_set("@#{attr}", object.send(attr))
        end
      end
    end

    def build_method(method_name)
      return unless method_name.present?

      self.class.send(:define_method, method_name) do
        instance_variable_get "@#{method_name}"
      end

      self.class.send(:define_method, "#{method_name}=") do |val|
        send("#{method_name}_will_change!") unless val == instance_variable_get("@#{method_name}")
        instance_variable_set("@#{method_name}", val)
      end

      self.class.send(:define_attribute_method, method_name)
    end

    def object_attributes_list(object, attrs_list)
      if attrs_list.present?
        attrs_list.uniq
      elsif object.is_a? RecursiveOpenStruct
        object.to_h.keys
      elsif object.is_a?(Hash) || object.is_a?(HashWithIndifferentAccess)
        object.keys
      elsif object.is_a? Object
        object.instance_variables.map { |att| att.to_s[1..-1].to_sym }
      else
        []
      end
    end

    def map_instance_variables_to_values_array(variables)
      variables.map { |v| [v.to_s[1..-1].to_sym, instance_variable_get(v.to_s)] }
    end

    def exclude_items_from_list(items_to_exclude, source_list)
      source_list.reject { |item| items_to_exclude.include?(item.to_s) }
    end

    def method_missing(method, *args)
      if method.present?
        new_attribute = method.to_s.gsub(%r{[^0-9a-z_]}i, '')
        build_method(new_attribute)
        args.empty? ? send(method) : send(method, args[0])
      else
        super
      end
    end

    def respond_to_missing?(method_name, *args)
      instance_variables.include?(method_name.to_s.gsub(%r{[^0-9a-z_]}i, '')) || super
    end
  end
end

