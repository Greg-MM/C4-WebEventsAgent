# C4-WebEventsAgent
Web Events Agent for Control4 - Execute Programming w/ HTTP(S) GET Requests
Features:
- Supports Creating Events (Composer Actions Tab)
- Support Setting Other Driver's Variables (Directly w/ GET Request)
- Can Set TLS Certificate & Private Key
- Password Required through Query Paramater (might add Digest support later)
- Supports EventID's up to 5000000
- Use "Get Commands (HTML)" URL in Agent Properties to Enumerate URLs (See Second Image Below)
- Can Read Driver's Variable (one at a time currently) w/ GET Request
   - can get all in XML or JSON, but I wouldn't poll that endpoint very often for performance reasons
   - GetVariable could be extended to support retrieving multiple values if there is interest
![WebEventsAgent_Composer](https://github.com/Greg-MM/C4-WebEventsAgent/assets/54459832/b9a14019-45fb-4cf0-99bc-d52400d137bf)
![WebEventsAgent_WebPage](https://github.com/Greg-MM/C4-WebEventsAgent/assets/54459832/219e2eb1-5254-4a24-bbea-37032fa65183)
