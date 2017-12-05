module MechanizeHelper
  extend self

  def agent(user_agent = :use_mozilla)
    Mechanize.new.tap do |agent|
      agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      if user_agent == :use_mozilla
        agent.user_agent_alias = 'Linux Mozilla'
      else
        agent.user_agent = user_agent
      end
    end
  end
end
