({
    nameMapping: {
        'downgrade': 'downgrade',
        'close': 'close',
        'cancel': 'cancel',
        'save': 'save',
        'winback': 'winback',
        'downsell': 'downsell',
        'downsellwithretention': 'downsell'
    },
    configStore:
        {
            'downgrade': {
                'Why is this opportunity being Downgraded?': {
                    primary: true,
                    config: {
                        name: 'Why is this opportunity being Downgraded?',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Downgrade_Reason__c',
                        plFieldNameDependent: null,
                        multiple: false,
                        required: true,
                        finalPanel: false,
                        display: 'group',
                    },
                    dependencies: [
                    // {
                    //     configName: 'Who did we lose to?',
                    //     conditions: {
                    //         DGW_Downgrade_Reason__c: 'Opportunity Lost',
                    //     }
                    // },
                        {
                            configName: 'What is the Primary Loss Reason?',
                            conditions: {
                                DGW_Downgrade_Reason__c: 'Opportunity Lost',
                            }
                        },
                        {
                            configName: 'Why is the opportunity Delayed?',
                            conditions: {
                                DGW_Downgrade_Reason__c: 'Delayed Opportunity',
                            }
                        },
                        {
                            configName: 'Why is the opportunity Invalid?',
                            conditions: {
                                DGW_Downgrade_Reason__c: 'Invalid Opportunity',
                            }
                        },
                    ],
                },
                // 'Who did we lose to?': {
                //     config: {
                //         name: 'Who did we lose to?',
                //         obj: 'Opportunity',
                //         plFieldName: 'DGW_Who_Did_we_lose_to__c',
                //         plFieldNameDependent: null,
                //         multiple: false,
                //         required: true,
                //         finalPanel: false,
                //         display: 'group',
                //     },
                //     dependencies: [{
                //         configName: 'Competitor',
                //         conditions: {
                //             DGW_Who_Did_we_lose_to__c: '*',
                //         }
                //     }
                //     ],
                // },
        
                'What is the Primary Loss Reason?': {
                    config: {
                        name: 'What is the Primary Loss Reason?',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Primary_Loss_Reason__c',
                        plFieldNameDependent: null,
                        multiple: false,
                        required: true,
                        finalPanel: true,
                        display: 'group',
                    },
                    dependencies: [
                    {
                        configName: 'Competitor',
                        conditions: {
                           DGW_Primary_Loss_Reason__c: 'Negative Customer Perception;Price;Missing Features;Lack of Global Offering;Access to Decision Maker/Signatory;RFP Submitted & no/negative response;Stayed With Incumbent;Access to Customer (Partner Controlled)'
                        }
                    },

                    {
                        configName: 'What was the negative content about?',
                        conditions: {
                            DGW_Primary_Loss_Reason__c: 'Negative Customer Perception',
                        }
                    },
                        {
                            configName: 'Why did we lose on Price?',
                            conditions: {
                                DGW_Primary_Loss_Reason__c: 'Price',
                            }
                        },
                        {
                            configName: 'Who did we escalate to?',
                            conditions: {
                                DGW_Primary_Loss_Reason__c: 'Price',
                            }
                        },
                        {
                            configName: 'Was there an opportunity to price match?',
                            conditions: {
                                DGW_Primary_Loss_Reason__c: 'Price',
                            }
                        },
                        {
                            configName: 'What are Secondary Loss Reasons? (Optional)',
                            conditions: {
                                DGW_Primary_Loss_Reason__c: 'Missing Features',
                            }
                        },
                        {
                            configName: 'What are Secondary Loss Reasons? (Optional)',
                            conditions: {
                                DGW_Primary_Loss_Reason__c: 'Lack of Global Offering',
                            }
                        },
                    ],
                },
                'Competitor': {
                    config: {
                        name: 'Competitor',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Competitors_Categories_Loss__c',
                        plFieldNameDependent: 'DGW_Competitor_Loss_List__c',
                        multiple: true,
                        required: true,
                        finalPanel: false,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Other',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 3,
                                        obj: 'Opportunity',
                                        plFieldName: 'DGW_Competitor_Other_Detail__c',
                                    }
                                ]
                            },
                        ]
                    },
                    dependencies: [
                    // {
                    //     configName: 'What is the Primary Loss Reason?',
                    //     conditions: {
                    //         DGW_Competitor_Loss_List__c: '*',
                    //     }
                    // },
                    ],
                },
                'What was the negative content about?': {
                    config: {
                        name: 'What was the negative content about?',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Negative_Customer_Perception__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        required: true,
                        finalPanel: false,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Call Quality',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Call_Quality_List__c',
                                }]
                            },
                            {
                                value: 'Uptime / SLA',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Uptime_List__c',
                                }]
                            },
                            {
                                value: 'Implementation / Support',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Implementation_List__c',
                                }]
                            },
                            {
                                value: 'Ease of Use',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Ease_of_Use_List__c',
                                }]
                            },
                            {
                                value: 'Scalability',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Scalability_List__c',
                                }]
                            },
                            {
                                value: 'Ordering Process',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Ordering_Process_List__c',
                                }]
                            },
                            {
                                value: 'Advanced Reporting',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Advanced_Reporting_List__c',
                                }]
                            },
                            {
                                value: 'Call Center Functionality',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Call_Center_List__c',
                                }]
                            },
                            {
                                value: 'Admin Controls',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Admin_Controls_List__c',
                                }]
                            },
                            {
                                value: 'Security / Compliance',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Security_List__c',
                                }]
                            },
                            {
                                value: 'Integrations',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_Integrations_List__c',
                                }]
                            },
                            {
                                value: 'Other',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 5,
                                        obj: 'Opportunity',
                                        plFieldName: 'DGW_Negative_Other_Detail__c',
                                    }
                                ]
                            }
                        ]
                    },
                    dependencies: [{
                        configName: 'What are Secondary Loss Reasons? (Optional)',
                        conditions: {
                            DGW_Negative_Customer_Perception__c: 'Call Quality;Uptime / SLA;Implementation / Support;Ease of Use;Scalability;Ordering Process;Advanced Reporting;Call Center Functionality;Admin Controls;Security / Compliance;Integrations',
                        }
                    },
                        {
                            configName: 'Other: What was the primary source?',
                            conditions: {
                                DGW_Negative_Customer_Perception__c: 'Other',
                            }
                        },
                    ],
                },
                'Other: What was the primary source?': {
                    config: {
                        name: 'Other: What was the primary source?',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Other_list__c',
                        plFieldNameDependent: null,
                        required: true,
                        finalPanel: false,
                        multiple: false,
                        display: 'group',
                    },
                    dependencies: [
                        {
                            configName: 'What are Secondary Loss Reasons? (Optional)',
                            conditions: {
                                DGW_Other_list__c: '*',
                            }
                        }
                    ],
                },
                'Why did we lose on Price?': {
                    config: {
                        name: 'Why did we lose on Price?',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Why_did_we_lose_on_Price__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        required: true,
                        finalPanel: false,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Phones too Expensive',
                                configs: [
                                    {
                                        type: 'picklist',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'DGW_competitor_price_phones__c',
                                    }]
                            },
                            {
                                value: 'Service too Expensive',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_competitor_price_service__c',
                                }]
                            },
                            {
                                value: 'Implementation too Expensive',
                                configs: [{
                                    type: 'picklist',
                                    required: true,
                                    obj: 'Opportunity',
                                    plFieldName: 'DGW_competitor_price_implementation__c',
                                }]
                            },
                        ]
                    },
                    dependencies: [{
                        configName: 'What are Secondary Loss Reasons? (Optional)',
                        conditions: {
                            DGW_Why_did_we_lose_on_Price__c: 'Service too Expensive;Implementation too Expensive',
                        }
                    },
                        {
                            configName: 'Were free phones given?',
                            conditions: {
                                DGW_Why_did_we_lose_on_Price__c: 'Phones too Expensive',
                            }
                        },
                    ],
                },
                'Who did we escalate to?': {
                    config: {
                        name: 'Who did we escalate to?',
                        obj: 'Opportunity',
                        plFieldName: 'What_level_did_we_escalate_to__c',
                        plFieldNameDependent: null,
                        required: true,
                        finalPanel: true,
                        multiple: false,

                        display: 'group',
                    },
                    // dependencies: [{
                    //     configName: 'What was their response?',
                    //     conditions: {
                    //         What_level_did_we_escalate_to__c: '*',
                    //     }
                    // }
                    // ],
                },
                'Was there an opportunity to price match?': {
                    config: {
                        name: 'Was there an opportunity to price match?',
                        obj: 'Opportunity',
                        plFieldName: 'Was_there_an_opportunity_to_price_match__c',
                        plFieldNameDependent: null,
                        required: true,
                        finalPanel: false,
                        multiple: false,

                        display: 'group',
                    },
                    // dependencies: [{
                    //     configName: 'What was their response?',
                    //     conditions: {
                    //         What_level_did_we_escalate_to__c: '*',
                    //     }
                    // }
                    // ],
                },
                'Were free phones given?': {
                    config: {
                        name: 'Were free phones given?',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Were_free_phones_given__c',
                        plFieldNameDependent: null,
                        required: true,
                        finalPanel: false,
                        multiple: false,

                        display: 'group',
                    },
                    dependencies: [{
                        configName: 'What are Secondary Loss Reasons? (Optional)',
                        conditions: {
                            DGW_Were_free_phones_given__c: '*',
                        }
                    }
                    ],
                },
                'What are Secondary Loss Reasons? (Optional)': {
                    config: {
                        name: 'What are Secondary Loss Reasons? (Optional)',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Secondary_Loss_Reasons__c',
                        plFieldNameDependent: null,
                        required: false,
                        finalPanel: true,
                        multiple: true,

                        display: 'group',
                    },
                    dependencies: [],
                },
                'Why is the opportunity Delayed?': {
                    config: {
                        name: 'Why is the opportunity Delayed?',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Why_is_the_opportunity_Delayed__c',
                        plFieldNameDependent: null,
                        multiple: false,
                        required: true,
                        finalPanel: true,
                        display: 'group',
                    },
                    dependencies: [{
                        configName: 'When should we follow-up?',
                        conditions: {
                            DGW_Project_Delayed_Detail__c: '*',
                        }
                    },],
                },
                'Why is the opportunity Invalid?': {
                    config: {
                        name: 'Why is the opportunity Invalid?',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_Why_is_the_opportunity_Invalid__c',
                        plFieldNameDependent: null,
                        multiple: false,
                        required: true,
                        finalPanel: true,
                        display: 'group',
                    },
                    dependencies: [],
                },
                'When should we follow-up?': {
                    config: {
                        name: 'When should we follow-up?',
                        obj: 'Opportunity',
                        plFieldName: 'DGW_When_should_we_follow_up__c',
                        plFieldNameDependent: null,
                        multiple: false,
                        required: true,
                        finalPanel: true,
                        display: 'group',
                    },
                    dependencies: [],
                },
            },
            'close': {
                'Who did/will we beat?': {
                    primary: true,
                    config: {
                        name: 'Who did/will we beat?',
                        obj: 'Opportunity',
                        plFieldName: 'CW_Categories_Who_did_we_beat__c',
                        plFieldNameDependent: 'CW_Who_did_we_beat__c',
                        multiple: true,
                        required: true,
                        finalPanel: false,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Other',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 3,
                                        obj: 'Opportunity',
                                        plFieldName: 'CW_Categories_Who_did_we_beat_other__c',
                                    }
                                ]
                            },
                        ]
                    },
                    dependencies: [
                        {
                            configName: 'Who did/will we replace?',
                            conditions: {
                                CW_Who_did_we_beat__c: '*'
                            }
                        }
                    ]
                },
                'Who did/will we replace?': {
                    config: {
                        name: 'Who did/will we replace?',
                        obj: 'Opportunity',
                        plFieldName: 'CW_Categories_Who_did_we_replace__c',
                        plFieldNameDependent: 'CW_Who_did_we_replace__c',
                        multiple: true,
                        required: true,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Other',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 3,
                                        obj: 'Opportunity',
                                        plFieldName: 'CW_Categories_Who_did_we_replace_other__c',
                                    }
                                ]
                            },
                        ]
                    },
                    dependencies: [
                        {
                            configName: 'What is the Primary Reason we won/will win?',
                            conditions: {
                                CW_Who_did_we_replace__c: '*'
                            }
                        }
                    ]
                },
                'What is the Primary Reason we won/will win?': {
                    config: {
                        name: 'What is the Primary Reason we won/will win?',
                        obj: 'Opportunity',
                        plFieldName: 'CW_Primary_Win_Reason__c',
                        plFieldNameDependent: null,
                        multiple: false,
                        required: true,
                        display: 'group'
                    },
                    dependencies: [
                        {
                            configName: 'Which Features?',
                            conditions: {
                                CW_Primary_Win_Reason__c: 'Features'
                            }
                        },
                        {
                            configName: 'How much is the customer saving year over year?',
                            conditions: {
                                CW_Primary_Win_Reason__c: 'Annualized Savings'
                            }
                        },
                        {
                            configName: 'What was the primary source?',
                            conditions: {
                                CW_Primary_Win_Reason__c: 'Awards/Good Reviews'
                            }
                        },
                        {
                            configName: 'What are Secondary Reasons we won/will win?',
                            conditions: {
                                CW_Primary_Win_Reason__c: 'Existing Customer/Upsell;Channel Relationship'
                            }
                        },
                    ]
                },
                'Which Features?': {
                    config: {
                        name: 'Which Features?',
                        obj: 'Opportunity',
                        plFieldName: 'CW_Win_Reason_Features__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        required: true,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Enterprise Features',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 5,
                                        obj: 'Opportunity',
                                        plFieldName: 'CW_Win_Reason_Features_enterprise__c',
                                    }
                                ]
                            },
                        ]
                    },
                    dependencies: [
                        {
                            configName: 'Which Integrations?',
                            conditions: {
                                CW_Win_Reason_Features__c: 'Integrations'
                            }
                        },
                        {
                            configName: 'What are Secondary Reasons we won/will win?',
                            conditions: {
                                CW_Win_Reason_Features__c: 'Call Quality;Uptime / SLA;Implementation / Support;Ease of Use;Scalability;Contact Center;Meetings / Video;Glip;Platform;Global Office;Security / Compliance;Enterprise Features'
                            }
                        }
                    ]
                },
                'Which Integrations?': {
                    config: {
                        name: 'Which Integrations?',
                        obj: 'Opportunity',
                        plFieldName: 'CW_Win_Reason_Integrations__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        required: true,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Other',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 3,
                                        obj: 'Opportunity',
                                        plFieldName: 'CW_Win_Reason_Integrations_other__c',
                                    }
                                ]
                            },
                        ]
                    },
                    dependencies: [
                        {
                            configName: 'What are Secondary Reasons we won/will win?',
                            conditions: {
                                CW_Win_Reason_Integrations__c: '*'
                            }
                        }
                    ]
                },
                'What was the primary source?': {
                    config: {
                        name: 'What was the primary source?',
                        obj: 'Opportunity',
                        plFieldName: 'CW_Win_Reason_Awards__c',
                        plFieldNameDependent: null,
                        multiple: false,
                        required: true,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Other Customer',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 5,
                                        obj: 'Opportunity',
                                        plFieldName: 'CW_Win_Reason_Awards_other__c',
                                    }
                                ]
                            },
                            {
                                value: 'Other Site',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 5,
                                        obj: 'Opportunity',
                                        plFieldName: 'CW_Win_Reason_Awards_other__c',
                                    }
                                ]
                            },
                            {
                                value: 'Other Award',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 5,
                                        obj: 'Opportunity',
                                        plFieldName: 'CW_Win_Reason_Awards_other__c',
                                    }
                                ]
                            },
                        ]
                    },
                    dependencies: [
                        {
                            configName: 'What are Secondary Reasons we won/will win?',
                            conditions: {
                                CW_Win_Reason_Awards__c: '*'
                            }
                        }
                    ]
                },
                'How much is the customer saving year over year?': {
                    config: {
                        name: 'How much is the customer saving year over year?',
                        obj: 'Opportunity',
                        plFieldName: 'CW_Win_Reason_Savings__c',
                        plFieldNameDependent: null,
                        multiple: false,
                        display: 'group',
                        required: true,
                        finalPanel: false
                    },
                    dependencies: [
                        {
                            configName: 'What are Secondary Reasons we won/will win?',
                            conditions: {
                                CW_Win_Reason_Savings__c: '*'
                            }
                        }
                    ]
                },
                'What are Secondary Reasons we won/will win?': {
                    config: {
                        name: 'What are Secondary Reasons we won/will win?',
                        obj: 'Opportunity',
                        plFieldName: 'CW_Secondary_Win_Reason__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        required: false,
                        finalPanel: true,
                        display: 'group'
                    },
                    dependencies: []
                }
            },
            'cancel': {
                'Select Churn Reason': {
                    primary: true,
                    config: {
                        name: 'Select Churn Reason',
                        obj: 'Opportunity',
                        plFieldName: 'Retention_Save_Why_DownsellParent__c',
                        plFieldNameDependent: 'Retention_Save_Why_DownsellChild__c',
                        multiple: true,
                        required: true,
                        finalPanel: false,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Outages',
                                configs: [
                                    {
                                        type: 'date',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Cancel_OutageDate__c',
                                    }
                                ]
                            },
                            {
                                value: 'Consolidating RC Accounts',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 1,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Cancel_NewUID__c',
                                    }
                                ]
                            },
                            {
                                value: 'QoS',
                                configs: [
                                    {
                                        type: 'picklist',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Cancel_QoS_WorkedSupport__c',
                                    }
                                ]
                            },
                            {
                                value: 'Issues not resolved',
                                configs: [
                                    {
                                        type: 'picklist',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Cancel_INR_WorkedSupport__c',
                                    }
                                ]
                            },
                        ]

                    },
                    dependencies: [{
                        configName: 'What Phone system to use?',
                        conditions: {
                            Retention_Save_Why_DownsellParent__c: '*',
                        }
                    },
                    ],
                },

                'What Phone system to use?': {
                    primary: false,
                    config: {
                        name: 'What Phone system to use?',
                        obj: 'Opportunity',
                        plFieldName: 'Retention_Cancel_PhoneSystem__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        required: true,
                        finalPanel: false,
                        display: 'group'
                    },

                    dependencies: [
                        {
                            configName: 'Addtional Details',
                            conditions: {
                                Retention_Cancel_PhoneSystem__c: '*'
                            }
                        }
                    ]

                },
                'Addtional Details': {
                    primary: false,
                    config: {
                        name: 'Addtional Details',
                        obj: 'Opportunity',
                        plFieldName: 'Retention_Cancel_AdditionalMain__c',
                        plFieldNameDependent: 'Retention_Cancel_SubDetail__c',
                        multiple: true,
                        required: true,
                        finalPanel: true,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Call Notation',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 15,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Cancel_CallNotes__c',
                                    }
                                ]
                            },
                            {
                                value: 'Flag for Internal Investigation?',
                                configs: [
                                    {
                                        type: 'picklist',
                                        required: false,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Cancel_FlaggedInvestigation__c',
                                    }
                                ]
                            }
                        ]
                    }
                }
            },
            'save': {
                'What\'s Changing?': {
                    primary: true,
                    config: {
                        name: 'What\'s Changing?',
                        obj: 'Opportunity',
                        plFieldName: 'Retention_Save_Whats_Changing_Main__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        required: true,
                        finalPanel: false,
                        display: 'group',
                        additionalOptions: []
                    },
                    dependencies: [
                        {
                            configName: 'Why is the customer Downselling?',
                            conditions: {
                                Retention_Save_Whats_Changing_Main__c: '*'
                            }
                        }
                    ]
                },
                'Why is the customer Downselling?': {
                    primary: false,
                    config: {
                        name: 'Why is the customer Downselling?',
                        obj: 'Opportunity',
                        plFieldName: 'Retention_Save_Why_DownsellParent__c',
                        plFieldNameDependent: 'Retention_Save_Why_DownsellChild__c',
                        multiple: true,
                        required: true,
                        finalPanel: false,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Outages',
                                configs: [
                                    {
                                        type: 'date',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_OutageDate__c',
                                    }
                                ]
                            },
                            {
                                value: 'Consolidating RC Accounts',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 1,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_NewUID__c',
                                    }
                                ]
                            },
                            {
                                value: 'Missing Critical Feature',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 1,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_FeatureNeeded__c',
                                    }
                                ]
                            },
                            {
                                value: 'QoS',
                                configs: [
                                    {
                                        type: 'picklist',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_QoS_WorkedSupport__c',
                                    }
                                ]
                            },
                            {
                                value: 'Issues not resolved',
                                configs: [
                                    {
                                        type: 'picklist',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_INR_WorkedSupport__c',
                                    }
                                ]
                            },

                        ]
                    },
                    dependencies: [
                        {
                            configName: 'Addtional Details',
                            conditions: {
                                Retention_Save_Why_DownsellParent__c: '*'
                            }
                        }
                    ]
                },
                'Addtional Details': {
                    primary: false,
                    config: {
                        name: 'Addtional Details',
                        obj: 'Opportunity',
                        plFieldName: 'Retention_Save_AdditionalMain__c',
                        plFieldNameDependent: 'Retention_Save_SubDetail__c',
                        multiple: true,
                        required: true,
                        finalPanel: true,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Call Notation',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 15,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_CallNotes__c',
                                    }
                                ]
                            },
                            {
                                value: 'Other',
                                configs: [
                                    {
                                        type: 'text',
                                        required: true,
                                        stringLength: 1,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_AppeasementOther__c',
                                    }
                                ]
                            },
                            {
                                value: 'Appeasement Offered',
                                configs: [
                                    {
                                        type: 'picklist',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_SubDetail__c',
                                    }
                                ]
                            },
                            {
                                value: 'Flag for Internal Investigation?',
                                configs: [
                                    {
                                        type: 'picklist',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_FlaggedInvestigation__c',
                                    }
                                ]
                            },
                            {
                                value: 'Customer Accepted Appeasement?',
                                configs: [
                                    {
                                        type: 'picklist',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Retention_Save_AcceptAppeasement__c',
                                    }
                                ]
                            },
                        ]
                    }
                }
            },
            'winback': {
                'How did we win them back?': {
                    primary: true,
                    config: {
                        name: 'How did we win them back?',
                        obj: 'Opportunity',
                        plFieldName: 'Retention_Winback_How_did_we__c',
                        plFieldNameDependent: 'Retention_Winback_What_was__c',
                        multiple: true,
                        required: true,
                        finalPanel: false,
                        display: 'group',
                    },
                    dependencies: [{
                        configName: 'What was used to win them back?',
                        conditions: {
                            Retention_Winback_How_did_we__c: '*',
                        }
                    },
                    ],
                },
                'What was used to win them back?': {
                    config: {
                        name: 'What was used to win them back?',
                        obj: 'Opportunity',
                        plFieldName: 'Retention_Winback_What_was__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        required: true,
                        finalPanel: true,
                        display: 'group',
                        additionalOptions: []
                    }
                }
            },
            'downsell': {
                'What\'s changing': {
                    primary: true,
                    config: {
                        name: 'What\'s changing',
                        obj: 'Opportunity',
                        plFieldName: 'Service_change_options__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        display: 'group'
                    },
                    dependencies: [{
                        configName: 'Churn and Sub Churn reasons',
                        conditions: {
                            Service_change_options__c: '*',
                        }
                    },
                    ],
                },
                'Churn and Sub Churn reasons': {
                    config: {
                        name: 'Churn and Sub Churn reasons',
                        obj: 'Opportunity',
                        plFieldName: 'Churn_reason__c',
                        plFieldNameDependent: 'Sub_Churn_reason__c',
                        multiple: false,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Enter the date of the outage:',
                                configs: [
                                    {
                                        type: 'date',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Sub_Churn_reason_detail_date__c',
                                    }
                                ]
                            },
                        ]
                    },
                    dependencies: [{
                        configName: 'What will customer use instead',
                        conditions: {
                            Churn_reason__c: '*'
                        }
                    },
                    ],
                },
                'What will customer use instead': {
                    config: {
                        name: 'What will customer use instead',
                        obj: 'Opportunity',
                        plFieldName: 'Replacement_option__c',
                        plFieldNameDependent: 'Replacement_suboption__c',
                        multiple: false,
                        required: true,
                        finalPanel: true,
                        display: 'group'
                    }
                }
            },
            'downsellwithretention': {
                'What\'s changing': {
                    primary: true,
                    config: {
                        name: 'What\'s changing',
                        obj: 'Opportunity',
                        plFieldName: 'Service_change_options__c',
                        plFieldNameDependent: null,
                        multiple: true,
                        display: 'group'
                    },
                    dependencies: [{
                        configName: 'Churn and Sub Churn reasons',
                        conditions: {
                            Service_change_options__c: '*',
                        }
                    },
                    ],
                },
                'Churn and Sub Churn reasons': {
                    config: {
                        name: 'Churn and Sub Churn reasons',
                        obj: 'Opportunity',
                        plFieldName: 'Churn_reason__c',
                        plFieldNameDependent: 'Sub_Churn_reason__c',
                        multiple: false,
                        display: 'group',
                        additionalOptions: [
                            {
                                value: 'Enter the date of the outage:',
                                configs: [
                                    {
                                        type: 'date',
                                        required: true,
                                        obj: 'Opportunity',
                                        plFieldName: 'Sub_Churn_reason_detail_date__c',
                                    }
                                ]
                            },
                        ]
                    },
                    dependencies: [{
                        configName: 'What will customer use instead',
                        conditions: {
                            Churn_reason__c: '*'
                        }
                    },
                    ],
                },
                'What will customer use instead': {
                    config: {
                        name: 'What will customer use instead',
                        obj: 'Opportunity',
                        plFieldName: 'Replacement_option__c',
                        plFieldNameDependent: 'Replacement_suboption__c',
                        multiple: false,
                        display: 'group'
                    },
                    dependencies: [{
                        configName: 'Retention Status',
                        conditions: {
                            Replacement_option__c: '*'
                        }
                    },
                    ],
                },
                'Retention Status': {
                    config: {
                        name: 'Retention Status',
                        obj: 'Opportunity',
                        plFieldName: 'Retention__c',
                        plFieldNameDependent: null,
                        multiple: false,
                        required: true,
                        finalPanel: true,
                        display: 'group'
                    }
                }
            }
        },
    configuration: {},

    ERROR_MESSAGES: {
        default: 'Something went wrong',
        empty_wizard_type: 'Wizard type missing or unsupported',
        empty_wizard_config: 'Configuration for this wizard type was not found',
        empty_opportunityId: 'Missing Opportunity Id',
    },

    PART_REGEX_STR: '[\\w\\s\\?\\.\\+\'\\(\\)&%/-]+',

    /*
     * Config for render one panel
     */
    getConfig: function (res) {
        const result = {
            name: res.name,
            label: res.name,
            display: res.display,
            multiple: res.multiple,
            value: res.value,
            options: this.parseDependencyList(JSON.parse(res.options), JSON.parse(res.optionsOrdered)),

            plFieldName: this.configuration[res.name].config.plFieldName,
            plFieldNameDependent: this.configuration[res.name].config.plFieldNameDependent,
            required: (this.configuration[res.name].config.required === true),
            finalPanel: (this.configuration[res.name].config.finalPanel === true),
        };

        // applyAdditionalConfig
        result.options = _.map(result.options, this.applyAdditionalConfig.bind(this, res));
        return result;
    },

    /*
     * Config for PanelItem
     */
    getOption: function (value, _options, _parent) {
        const name = value;
        const parent = (_parent || null);
        const label = this.parseLabel(value);
        const type = (_options && _options.length) ? 'container' : this.parseType(value);
        const required = this.isRequired(value).required;
        const options = (_options && _options.length) ? this.parseOptions(_options, value) : null;
        const additionalOptions = this.getAdditionalOptionStr(value) ? [this.getAdditionalOptionStr(value)] : null;

        return {
            name: name,
            parent: parent,
            label: label,
            type: type,
            value: null, // ???
            checked: false,
            required: required,
            options: options,
            error: null, // ???
            additionalOptions: additionalOptions
        };
    },

    /*
     * Additional option determined by value
     */
    getAdditionalOptionStr: function (value, name) {
        if (!this.parseField(value)) {
            return null;
        }

        return {
            name: this.parseField(value).fieldName,
            type: this.parseType(value),
            label: this.parseField(value).fieldLabel,
            value: null,
            required: this.isRequired(value).required,
            stringLength: this.isRequired(value).stringLength,
            show: !name,
            condition: name && {name: name, value: value}
        };
    },

    getAdditionalOption: function (aConfig) {
        let option;

        if (aConfig.type === 'picklist') {
            option = this.getPicklist(aConfig);
        } else if (aConfig.type === 'text' || aConfig.type === 'date') {
            option = this.getInput(aConfig);
        }

        return option;
    },

    /*
     * Additional picklist option
     */
    getPicklist: function (aConfig) {
        let values = [{
            label: '--None--',
            value: false,
            class: 'optionClass'
        }];

        values = values.concat(_.map(JSON.parse(aConfig.options), this.getPicklistOptions, this));

        return {
            name: aConfig.name,
            label: aConfig.label,
            type: aConfig.type,
            values: values,
            value: null,
            required: aConfig.required,
            error: null,
            show: true,
        }
    },

    getPicklistOptions: function (option) {
        const label = this.parseLabel(option.value);

        return {
            label: label,
            value: option.value,
            class: 'optionClass'
        }
    },

    getInput: function (aConfig) {
        return {
            name: aConfig.name,
            label: aConfig.label,
            type: aConfig.type,
            required: aConfig.required,
            stringLength: aConfig.stringLength,
            value: null,
            show: true,
        }
    },

    /*
     *
     */
    applyAdditionalConfig: function (res, option) {
        if (option.options) {
            option.options = _.map(option.options, this.applyAdditionalConfig.bind(this, res));
        }

        if (option.type !== 'container') {
            const aConfigs = res.additionalConfigs && res.additionalConfigs[option.name];

            if (aConfigs) {
                option.additionalOptions = _.isArray(option.additionalOptions)
                    ? option.additionalOptions
                    : [];

                _.forEach(aConfigs, (aConfig) => {
                    let aOption = this.getAdditionalOption(aConfig);

                    aOption && option.additionalOptions.push(aOption);

                    // Additional options from AdditionalConfig values
                    _.forEach(JSON.parse(aConfig.options), (o) => {
                        let aOption = this.getAdditionalOptionStr(o.value, aConfig.name);
                        aOption && option.additionalOptions.push(aOption);
                    }, this);
                }, this);

            }

        }

        return option;

    },

    getWizardConfig: function(component) {
        const helper = this;
        const wizardType = component.get('v.wizardType');

        return helper.configStore[wizardType];
    },

    isWizardFieldsFilled: function (component, wizardConfig, opportunity) {
        const helper = this;

        const primaryStep = helper.getPrimaryWizardStep(component, wizardConfig);
        const primaryFields = helper.getWizardStepPrimaryFields(component, primaryStep);

        return _.reduce(primaryFields, (acc, field) => {
            return acc && !!opportunity[field];
        }, true);
    },

    collectRestoredValues: function (component, wizardConfig) {
        const helper = this;
        const oppData = component.get('v.opportunityWizardData');

        const result = {};
        _.forEach(wizardConfig, (step, name) => {
            const fieldValues = helper.getWizardStepFieldValues(component, step, oppData);

            result[name] = {
                hasErrors: false,
                name: name,
                values: fieldValues
            };
        });

        return result;
    },

    getWizardStepPrimaryFields: function (component, wizardStep) {
        const stepConfig = wizardStep.config;

        return _.filter([stepConfig.plFieldName, stepConfig.plFieldNameDependent], (fieldName) => {
            return !!fieldName;
        })
    },

    getWizardStepAdditionalFields: function (component, wizardStep) {
        const stepConfig = wizardStep.config;

        return _.flatten(_.map(stepConfig.additionalOptions, (option) => {
            return _.map(option.configs, (optionConfig) => {
                return optionConfig.plFieldName;
            })
        }));
    },

    getWizardStepFieldValues: function (component, wizardStep, oppData) {
        const helper = this;

        const primaryFields = helper.getWizardStepPrimaryFields(component, wizardStep);
        const additionalFields = helper.getWizardStepAdditionalFields(component, wizardStep);

        return _.reduce(_.flatten([primaryFields, additionalFields]), (acc, fieldName) => {
            acc[fieldName] = oppData[fieldName];

            return acc;
        }, {});
    },

    getPrimaryWizardStep: function (component, wizardConfig) {
        return _.find(wizardConfig, (wizardStep) => {
            return wizardStep.primary;
        });
    },

    getWizardSteps: function (component, wizardConfig, _wizardStepValues) {
        const helper = this;

        const primaryStep = helper.getPrimaryWizardStep(component, wizardConfig);
        const wizardStepValues = _wizardStepValues || helper.collectRestoredValues(component, wizardConfig);

        if (!primaryStep) {
            return [];
        }

        const queue = [primaryStep];
        const result = [];
        const existingSteps = {};
        while (queue.length > 0) {
            const currentStep = queue.shift();

            const stepName = currentStep.config.name;
            const stepDeps = currentStep.dependencies;

            _.forEach(stepDeps, (dep) => {
                if (wizardStepValues[stepName] && helper.checkDependencies(wizardStepValues[stepName], dep)) {
                    if (wizardConfig[dep.configName]) {
                        queue.push(wizardConfig[dep.configName]);
                    }
                }
            });

            if (!existingSteps[stepName]) {
                result.push(currentStep.config);
                existingSteps[stepName] = true;
            }
        }

        return result;
    },

    getWizardCurrentValues: function(component) {
        const panels = component.get('v.panels');

        return _.reduce(panels, (acc, panel) => {
            const label  = panel.get('v.data.label');
            const params = panel.get('v.params');
            const errors = panel.get('v.errorMap');

            acc[label] = params;
            acc[label].hasErrors = Object.keys(errors).length > 0;

            return acc;
        }, {});
    },

    getPanelConfigAll: function (component, wizardConfig) {
        const helper = this;
        const wizardSteps = helper.getWizardSteps(component, wizardConfig);

        component.set('v.global.isLoading', true);

        return this.request(component, 'c.getAllPanelConfigs', {params: JSON.stringify(wizardSteps)})
            .then($A.getCallback((res) => {
                _.forEach(res, (item) => {
                    const panelConfig = helper.getConfig(item);

                    helper.restoreValues(component, panelConfig);
                    helper.createPanel(component, panelConfig);
                });

                component.set('v.global.isLoading', false);

                helper.showSpinner(false);
            }))
            .catch($A.getCallback((res) => {
                console.error(res);

                _.forEach(res.getError(), (error) => {
                    helper.showError(error.message);
                });
            }));
    },

    getPanelConfig_ctrl: function (component, conf) {
        const helper = this;

        component.set('v.global.isLoading', true);

        return this.request(component, 'c.getPanelConfig', {params: conf})
            .then($A.getCallback((res) => {
                const panelConfig = helper.getConfig(res);

                helper.createPanel(component, panelConfig);

                component.set('v.global.isLoading', false);

                helper.showSpinner(false);
            }))
            .catch($A.getCallback((res) => {
                console.error(res);

                _.forEach(res.getError(), (error) => {
                    helper.showError(error.message);
                });
            }));
    },

    restoreValues: function (component, panelConfig) {
        const opp = component.get('v.opportunityWizardData');

        _.forEach(panelConfig.options, (option) => {
            const field = panelConfig.plFieldName;

            if (!opp[field]) {
                return;
            }

            const value = opp[field].split(';');

            _.forEach(value, (v) => {
                if (option.name === v) {
                    option.checked = true;
                }
            });

            if (option.checked) {
                if (option.additionalOptions && option.additionalOptions.length > 0) {
                    _.forEach(option.additionalOptions, (addOption) => {
                        const additionalField = addOption.name;

                        if (opp[additionalField]) {
                            addOption.value = opp[additionalField];
                        }
                    });
                }

                const depField = panelConfig.plFieldNameDependent;

                if (!opp[depField]) {
                    return;
                }

                const depValue = opp[depField].split(';');

                _.forEach(option.options, (suboption) => {
                    _.forEach(depValue, (dv) => {
                        if (suboption.name === dv) {
                            suboption.checked = true;
                        }
                    });
                    if (suboption.checked) {
                        if (suboption.additionalOptions && suboption.additionalOptions.length > 0) {
                            _.forEach(suboption.additionalOptions, (addOption) => {
                                const additionalField = addOption.name;

                                if (opp[additionalField]) {
                                    addOption.value = opp[additionalField];
                                }
                            });
                        }
                    }
                });
            }
        });
    },

    checkFinalPanelVisible: function (component) {
        const panels = component.get('v.panels');
        let canSave = false;

        _.forEach(panels, (p) => {
            canSave = canSave || p.get('v.data.finalPanel');
        });

        return canSave;
    },

    checkForCompletionAllForms: function (component) {
        const panels = component.get('v.panels');
        let isComplete = true;

        _.forEach(panels, (p) => {
            isComplete = isComplete && p.get('v.isComplete');
        });

        return isComplete;
    },

    createPanel: function (component, panelConfig) {
        const helper = this;
        const oppData = component.get('v.opportunityWizardData');
        const wizardType = component.get('v.wizardType');

        $A.createComponent(
            'c:OptionsPanel',
            {
                data: panelConfig,
                global: component.getReference('v.global'),
                isEditable: component.get('v.isEditable'),
                isInline: component.get('v.isInline'),
                isWizardDataLoaded: helper.isWizardFieldsFilled(component, helper.configStore[wizardType], oppData),
                isComplete: false,
            },
            (panel, status, errorMessage) => {
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    let panels = component.get('v.panels');

                    panels.push(panel);
                    panels = _.sortBy(panels, (p) => {
                        return p.get('v.data').finalPanel
                    });

                    const canSave = helper.checkForCompletionAllForms(component)
                        && helper.checkFinalPanelVisible(component);

                    component.set("v.panels", panels);
                    component.set('v.canSave', canSave);
                } else if (status === "INCOMPLETE") {
                    console.error("No response from server or client is offline.")
                    // Show offline error
                } else if (status === "ERROR") {
                    console.error("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    },

    setEditable: function (component, value) {
        const panels = component.get('v.panels');

        component.set('v.isEditable', !!value);

        _.forEach(panels, (panel) => {
            panel.set('v.isEditable', !!value);
        })
    },

    parseDependencyList: function (options, orderedOptions) {
        const result = [];

        // Array _.isArray(options)
        if (options.length) {
            for (let i = 0; i < options.length; i++) {
                result.push(this.getOption(options[i].value));
            }
        }
        // Object
        else {
            for (let i = 0; i < orderedOptions.length; i++) {
                for (let key in options) {
                    if (orderedOptions[i].value === key) {
                        result.push(this.getOption(key, options[key]));
                    }
                }
            }
        }

        return result;
    },

    isRequired: function (value) {
        const result = {
            required: false,
            stringLength: null
        };

        const arr = /\[\*\d*\]/.exec(value);
        if (arr) {
            result.required = true;
            result.stringLength = parseInt(arr[0]
                .replace('[*', '')
                .replace(']', ''));
        }

        return result;
    },

    parseType: function (value) {
        let result = 'checkbox';
        if (value.indexOf('[input]') > -1) {
            result = 'text';
        }
        if (value.indexOf('[date]') > -1) {
            result = 'date';
        }
        return result;
    },

    parseField: function (value) {
        const full = new RegExp('\\[\\w+\\(' + this.PART_REGEX_STR + '\\)\\]');
        const fName = new RegExp('^\\[(\\w+)');
        const fLabel = new RegExp('\\((' + this.PART_REGEX_STR + ')\\)');
        const mResult = value.match(full);
        let field;

        if (mResult) {
            // field
            const fieldName = mResult[0].match(fName);
            // label
            const fieldLabel = mResult[0].match(fLabel);

            field = {
                fieldName: fieldName && fieldName[1],
                fieldLabel: fieldLabel && fieldLabel[1]
            }
        }

        return field;
    },

    parseInputLabel: function (item) {
        let result = '';

        const s = item.split('[(');

        if (s[1]) {
            result = s[1].split(')]')[0];
        }

        return result;
    },

    parseLabel: function (value) {
        const label = new RegExp('(^' + this.PART_REGEX_STR + ')(\\[)?');
        const result = value.match(label);

        return result && result[1];
    },

    parseOptions: function (options, parent) {
        const result = [];

        for (let i = 0; i < options.length; i++) {
            result.push(this.getOption(options[i], null, parent));
        }

        return result;
    },

    getConfigList: function (panelParams, configDependency) {
        const helper = this;
        const configList = {add: [], remove: []};

        helper.checkDependencies(panelParams, configDependency)
            ? configList.add.push(configDependency.configName)
            : configList.remove.push(configDependency.configName);

        // filter remove list if it has items from list to add;
        configList.remove = _.filter(configList.remove, (removeItem) => {
            return (configList.add.indexOf(removeItem) === -1)
        });

        return configList;
    },

    checkDependencies: function (panelParams, configDependency) {
        if (panelParams.hasErrors === true) {
            return false;
        }

        return this.checkOptions(panelParams, configDependency);
    },

    getErrorsByPanel: function (component, panelParams) {
        const panels = component.get("v.panels");

        _.forEach(panels, (panel) => {
            if (panel.get("v.data.label") === panelParams.name && panel.get("v.isComplete") === false) {
                panelParams.hasErrors = true;
            }
        });
    },

    applyConfigList: function (component, configList) {
        const helper = this;
        let panels = component.get('v.panels');

        try {
            // remove
            if (configList.remove.length) {
                _.forEach(configList.remove, (configName) => {

                    if (helper.configuration[configName]) {
                        const panel = _.find(panels, panel => panel.get('v.data').name === configName);
                        if (panel) {
                            panels = helper.removePanel(panels, configName);

                            const getDependentConfigs = helper.getDependentConfigs(configName);

                            _.forEach(getDependentConfigs, (configName) => {
                                panels = helper.removePanel(panels, configName);
                            });
                        }
                    } else {
                        console.error('No configuration with name - ' + configName);
                    }

                });

                component.set('v.panels', panels);
            }

            // add
            if (configList.add.length) {
                _.forEach(configList.add, (configName) => {

                    if (helper.configuration[configName]) {
                        const panel = _.find(panels, panel => panel.get('v.data').name === configName);
                        if (!panel) {
                            let conf = helper.configuration[configName];
                            conf = JSON.stringify(conf.config);

                            helper.getPanelConfig_ctrl(component, conf);
                        }
                    } else {
                        console.error('No configuration with name - ' + configName);
                    }

                });
            }

        } catch (e) {
            console.error('applyConfigList() => ', e);
        }

    },

    getDependentConfigs: function (configName, _list) {
        const helper = this;
        const conf = helper.configuration[configName];
        const list = _list || [];

        if (conf) {
            const dependencies = conf.dependencies;

            _.forEach(dependencies, (d) => {
                list.push(d.configName);
                helper.getDependentConfigs(d.configName, list);
            });
        } else {
            console.error('No dependent configuration with name - ' + configName);
        }

        return list;
    },

    removePanel: function (panels, name) {
        const index = _.findIndex(panels, (panel) => {
            return (panel.get('v.data').name === name);
        });

        if (index > -1) {
            panels.splice(index, 1);
        }

        return panels;
    },

    checkOptions: function (item, dependency) {
        let result = true;

        _.mapObject(dependency.conditions,  (val, key) => {
            if (!this.checkOption(item.values[key], val)) {
                result = false;
            }
        }, this);

        return result;
    },

    checkOption: function (options, dependencyOption) {
        let result = false;

        if (!dependencyOption) {
            result = true; // dependencyOption is not assigned
        } else if (dependencyOption === '?') {
            result = true; // option should has any value, empty or filled
        } else if (dependencyOption === '*' && options) {
            result = true; // option should has any filled value
        } else if (options) {
            // option is equal or contain to dependencyOption
            _.forEach(dependencyOption.split(";"), (d) => {
                if (options.indexOf(d) > -1) {
                    result = true;
                }
            });
        }
        return result;
    },

    showError: function (message, details) {
        $A.get("e.c:ToastEvent").setParams({
            theme: 'error',
            header: message || this.ERROR_MESSAGES.default,
            details: details,
            defaultTimeout: false
        }).fire();
    },

    showSuccess: function (message, details) {
        $A.get("e.c:ToastEvent")
            .setParams({
                theme: 'success',
                header: message || 'Success',
                details: details,
                defaultTimeout: 5
            })
            .fire()
    },

    request: function (component, controller, params) {
        return new Promise((resolve, reject) => {
            const action = component.get(controller);
            if (params) {
                action.setParams(params);
            }
            action.setCallback(null, (response) => {
                if (response.getState() === 'SUCCESS') {
                    const res = response.getReturnValue();
                    resolve(res);
                } else {
                    reject(response);
                }
            });
            $A.enqueueAction(action);
        });
    },

    formSubmit: function (component, fieldValues) {
        const helper = this;

        const isInline = component.get('v.isInline');
        const oppId = component.get('v.oppId');
        const wizardType = component.get('v.wizardType');

        helper.showSpinner(true);

        return this.request(component, 'c.submitForm', {params: fieldValues})
            .then($A.getCallback((res) => {
                helper.showSpinner(false);

                if (isInline) {
                    if (res === oppId) {
                        helper.showSpinner(true);

                        component.set('v.panels', []);

                        helper.loadOppCloseInfo(component)
                            .then($A.getCallback(() => {
                                return helper.getPanelConfigAll(component, helper.configStore[wizardType]);
                            }))
                            .then($A.getCallback(() => {
                                const message = $A.get("{!$Label.c.RCOpportunityCompetitiveWinReasonsSaveSuccess}");
                                helper.showSuccess(message);
                                helper.setEditable(component, false);
                                helper.showSpinner(false);
                            }));
                    }
                } else {
                    window.location = '/' + res;
                }
            }))
            .catch($A.getCallback((res) => {
                console.error(res);

                helper.showSpinner(false);

                _.forEach(res.getError(), (error) => {
                    helper.showError(error.message);
                });
            }));
    },

    showSpinner: function (value, text) {
        $A.get('e.c:SpinnerEvent').setParams({
            value: value,
            text: text,
        }).fire();
    },

    showModal: function (component) {
        const helper = this;

        $A.get("e.c:ModalRequestEvent").setParams({
            header: $A.get("$Label.c.DW_Title_CloseOpportunity"),
            content: $A.get("$Label.c.DW_Message_CloseOpportunity"),
            buttons: [{
                label: 'Ok',
                variant: 'brand',
                callback: () => {
                    helper.modalActionOk(component);
                }
            }]
        }).fire();
    },

    modalActionOk: function (component) {
        const helper = this;
        const panels = component.get('v.panels');
        const oppId = component.get('v.opportunityId');
        const wType = component.get('v.wizardType').toLowerCase();
        const isInline = component.get('v.isInline');

        if (!oppId) {
            helper.showError(helper.ERROR_MESSAGES.empty_opportunityId);
            return;
        }

        const fieldValues = {};
        fieldValues.Id = oppId;

        _.forEach(panels, (panel) => {
            const params = panel.get('v.params');
            Object.assign(fieldValues, params.values);
        });

        fieldValues['wType'] = wType;
        fieldValues['isInline'] = isInline;
        fieldValues['brandName'] = component.get("v.opportunityWizardData")['Brand_Name__c'];

        helper.formSubmit(component, fieldValues);
    },

    redirectToOpportunity: function (component) {
        const oppId = component.get('v.opportunityId');

        if (oppId) {
            window.location = '/' + oppId;
        }
    },

    uncheckConfirmAndClose: function (component) {
        const helper = this;
        const oppId = component.get('v.opportunityId');

        helper.showSpinner(true);

        return this.request(component, 'c.uncheckConfirmAndClose', {opportunityId: oppId})
            .catch($A.getCallback((res) => {
                console.error(res);
                helper.showSpinner(false);

                _.forEach(res.getError(), (error) => {
                    helper.showError(error.message);
                });
            }));
    },

    loadOppCloseInfo: function (component) {
        const helper = this;
        const oppId = component.get('v.opportunityId');

        if (!oppId) {
            return new Promise().resolve(null);
        }

        return helper.request(component, 'c.getOpportunityCloseWizardData', {opportunityId: oppId})
            .then($A.getCallback((res) => {
                component.set('v.opportunityWizardData', res);
                return res;
            }))
            .catch($A.getCallback((res) => {
                console.error(res);

                helper.showSpinner(false);

                _.forEach(res.getError(), (error) => {
                    helper.showError(error.message);
                });
            }))
    },

    processOppInfo: function (component) {
        const helper = this;
        const oppInfo = component.get('v.oppInfo');
        const opty = JSON.parse(oppInfo);

        const isShowModal = opty.optyName.toLowerCase().indexOf('change order') === -1
            && opty.optyName.toLowerCase().indexOf('migration') === -1
            && !opty.parentOrder
            && !opty.isRenewalWithoutChanges
            && !opty.isSingleOne;

        if (isShowModal) {
            helper.showModal(component);
        } else {
            helper.modalActionOk(component);
        }
    },

    determineOpportunityId: function (component) {
        const oppId = component.get('v.oppId')
            ? component.get('v.oppId')
            : JSON.parse(component.get('v.oppInfo')).opportunityId;

        component.set('v.opportunityId', oppId);
    }
});