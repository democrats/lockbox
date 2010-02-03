module ActiveRecord
   module Validations
     module ClassMethods
   
       alias :real_validates_presence_of :validates_presence_of unless method_defined?(:real_validates_presence_of)
       alias :real_validates_acceptance_of :validates_acceptance_of unless method_defined?(:real_validates_acceptance_of)
   
       def validates_acceptance_of(*attr_names)
          self.add_required_fields(attr_names)
          real_validates_acceptance_of(*attr_names)
        end
        
       def validates_presence_of(*attr_names)
         self.add_required_fields(attr_names)
         real_validates_presence_of(*attr_names)
       end
       
       def add_required_fields(args)
         #get the options off the end of the array of attribute
         attr_names, options = extract_options(args)
         options[:on] = :save unless options.include?(:on)
         self.required_attributes = attr_names.inject({}) do |reqs, attr| 
           # reqs[attr] = options unless options.include?(:if) or options.include?(:unless) 
           reqs[attr] = options
           reqs
         end
       end
       
       def extract_options(array)
         array.last.is_a?(::Hash) ? [array[0...-1], array.last] : [array, {}]
       end

       def required_attributes=(hash)
         self.write_inheritable_hash(:required_attributes, hash)
       end
   
       def required_attributes
         self.read_inheritable_attribute(:required_attributes)
       end
       
     end
   end

   class Base
     
     def self.attribute_required?(attribute)
       return true if self.required_attributes.include?(attribute)
     end

     def attribute_required?(attribute)
       begin
         # return true if self.class.required_attributes.include?(attribute)
         return false unless self.class.required_attributes.include?(attribute)
         configuration = self.class.required_attributes[attribute]
         if ((configuration[:if] && !self.class.evaluate_condition(configuration[:if], self)) || 
            (configuration[:unless] && self.class.evaluate_condition(configuration[:unless], self)))
           return false
         else
           return true
         end
       rescue
         return false
       end
     end
     
   end

end
