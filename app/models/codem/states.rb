module Codem
  module States
    def self.included(base)
      base.class_eval do
        after_create { enter(initial_state) }
      end
    end

    def enter(state, parameters={})
      update_attributes :state => state

      method = "enter_#{state}"
      self.send(method, parameters)
    end

    def initial_state
      Codem::Scheduled
    end

    def receive_transcoder_callback(attributes)
      update_attributes :last_status_message => attributes['message']
      
      case attributes['status']
        when 'failed'
          enter(Codem::Failed, attributes)
        when 'success'
          enter(Codem::Completed, attributes)
      end
    end
    
    protected
      def enter_scheduled(parameters)
        Codem::Jobs.queue Codem::Jobs::ScheduleJob.new(self, parameters)
      end
      
      def enter_transcoding(parameters)
        update_attributes :remote_jobid => parameters['job_id'],
                          :transcoding_started_at => Time.now
      end

      def enter_on_hold(parameters)
        Codem::Jobs.queue Codem::Jobs::OnHoldJob.new(self, parameters)
      end
      
      def enter_complete(parameters)
        update_attributes :progress => '100.00',
                          :completed_at => Time.now
      end
      
      def enter_failed(parameters)
      end
  end
end
