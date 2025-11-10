class Message < ApplicationRecord
  enum sender_role: {
     initiator: "initiator",
     expert: "expert"
  }
end
