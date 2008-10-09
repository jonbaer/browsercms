module Cms
  ###
  #
  # Any programmer defined Block's should include BlockSupport via:
  #
  # include Cms::BlockSupport
  #
  # This will grant them instance and class methods from both BlockSupport and StatusSupport
  #
  module BlockSupport
    
    def self.included(base_class)
      base_class.extend ClassMethods
      base_class.class_eval do
        attr_accessor :connect_to_page_id
        attr_accessor :connect_to_container
        attr_accessor :connected_page
        after_create :connect_to_page         
      end
    end

    module ClassMethods
      def content_block_type
        to_s.underscore
      end

      #This is needed by path helper
      #We originally didn't have this and just used respond_to(:content_block_type)
      #In order to determine if the object is a content block, 
      #but that became a problem for connector, which is not a content block,
      #but does have a content_block_type method
      def content_block?
        true
      end

      def display_name
        to_s.titleize
      end

      def display_name_plural
        display_name.pluralize
      end
    end

    # Instance Methods
    def connected_pages
      Page.connected_to_block(self)
    end

    def content_block_type
      self.class.content_block_type
    end
  
    def display_name
      self.class.display_name
    end

    def display_name_plural
      self.class.display_name_plural
    end
    
    def connect_to_page
      unless connect_to_page_id.blank? || connect_to_container.blank?
        self.connected_page = Page.find(connect_to_page_id)
        connected_page.add_content_block!(self, connect_to_container)
      end
    end

    def publish_by_page=(page)
      @publish_by_page = page
    end

    def update_connected_pages
      Page.find_by_content_block(self, (version-1)).each do |page|
        update_page(page) unless @publish_by_page == page
      end      
    end

    def update_page(page)
      new_status = status == 'PUBLISHED' && page.status == 'PUBLISHED' ? 'PUBLISHED' : 'IN_PROGRESS'
      page.update_attributes!(:new_revision_comment => "Edited block", :new_status => new_status, :updated_by_user => updated_by)
      page.connectors.all(:include => :page, :conditions => {:content_block_id => self.id, :content_block_type => self.class.name }).each do |conn|
        conn.increment!(:content_block_version)
      end      
    end
  
  end
end