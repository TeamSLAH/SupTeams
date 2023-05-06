```json
{
   "Groups": [
      {
         "Name": "slah",
         "Users": [
            "xyz@suportis.com",
            "*andereGruppe"
         ]			
      },...
   ],
   "Teams": [
      {
         "Name": "Test",
         "Users": [
            "xyz@suportis.com",
            "*slah"
         ],
         "Channels": [
            {
                "Name": "Projekt 1",
                "Settings": [
                    ...
                ]
            },
            "*vorlage1"
         ]
      },...
   ],
   "ChannelTemplates": [
        {
            "Name": "vorlage1",
            "Channels": [
                {
                    "Name": "Projekt 2",
                    "Settings": [
                        ...
                    ]
                },
                "*vorlage2"
            ]
        }
   ]
}
```