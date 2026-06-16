var j$ = jQuery.noConflict();
			j$("#sidebarComponent").closest(".sidebarModule").prev().hide();
			function set_cookieHrs(name, value, expires, path, domain, secure) {
				var today = new Date();
				if (expires) {
					expires = 2 * 1000 * 60 * 60;
				}
				var expires_date = new Date(today.getTime() + (expires));
				document.cookie = name
						+ "="
						+ escape(value)
						+ ((expires) ? "; expires="
								+ expires_date.toGMTString() : "")
						+ ((path) ? "; path=" + path : "")
						+ ((domain) ? "; domain=" + domain : "")
						+ ((secure) ? ";secure" : "");
			}
			function set_cookieDay(name, value, expires, path, domain, secure) {
				var today = new Date();
				if (expires) {
					expires = 1 * 1000 * 60 * 60 * 24;
				}
				var expires_date = new Date(today.getTime() + (expires));
				document.cookie = name
						+ "="
						+ escape(value)
						+ ((expires) ? "; expires="
								+ expires_date.toGMTString() : "")
						+ ((path) ? "; path=" + path : "")
						+ ((domain) ? "; domain=" + domain : "")
						+ ((secure) ? "; secure" : "");
			}
			function set_cookieOLD(name, value, exp_y, exp_m, exp_d, path,
					domain, secure, expires) {
				var expires;
				var cookie_string = name + "=" + escape(value);
				if (expires > 0) {
					expires = 2 * 1000 * 60 * 60;
					alert(expires);
				}
				if (exp_y) {
					expires = new Date(exp_y, exp_m, exp_d);
					alert(expires);
					cookie_string += ";\n\expires=" + expires.toGMTString();
				}
				if (path)
					cookie_string += "; path=" + escape(path);
				if (domain)
					cookie_string += "; domain=" + escape(domain);
				if (secure)
					cookie_string += "; secure";
				document.cookie = cookie_string;
			}
			function get_cookie(cookie_name) {
				var results = document.cookie.match('(^|;) ?' + cookie_name
						+ '=([^;]*)(;|$)');
				if (results)
					return (unescape(results[2]));
				else
					return null;
			}
			var tipCount = 1;
			var maxTipCount = 7;
			var myDays = [ "Sunday", "Monday", "Tuesday", "Wednesday",
					"Thursday", "Friday", "Saturday", "Sunday" ];
			var today = new Date();
			tipCount = today.getDay();
			var thisDay = myDays[tipCount];
			var pageurl = document.location.href;
			j$(document)
					.ready(
							function() {
								j$.fx.speeds._default = 500;
								j$('#dialog')
										.dialog(
												{
													autoOpen : false,
													width : 600,
													height : 250,
													show : "slide",
													hide : "explode",
													buttons : {
														"I have read this" : function() {
															var getdivShowatSU = document
																	.getElementById("dialog_link");
															set_cookieHrs(
																	'userTipSettings',
																	'NO', true,
																	'', '', '');
															j$(this).dialog(
																	"close");
															j$('#dialog').html(
																	'');
														},
														"Close" : function() {
															var getdivShowatSU = document
																	.getElementById("dialog_link");
															j$(this).dialog(
																	"close");
															set_cookieDay(
																	'userTipSettings',
																	'NO', true,
																	'', '', '');
															j$('#dialog').html(
																	'');
														}
													}
												});
								j$('#dialog_link').click(function() {
									j$('#dialog').dialog('open');
									loadRemoteTip();
								});
								j$('.ui-icon.ui-icon-closethick').click(
										function() {
											j$('#dialog').html('');
										});
								if (j$('#dialog').dialog("isOpen") == false
										&& get_cookie("userTipSettings") != "NO"
										&& pageurl.indexOf('/home.jsp') > 0) {
									j$('#dialog').dialog('open');
									loadRemoteTip();
								}
							});
			function loadRemoteTip() {
				j$(document)
						.ready(
								function() {
									try {
										var messageDetails = getActiveMesageDetails(thisDay);
										if (messageDetails.size > 0) {
											var records = messageDetails
													.getArray("records");
											j$('#dialog').html('');
											j$('#dialog').dialog(
													"option",
													"title",
													'For Your Information <font style=\"font-size:larger;color:#C90101;\" >'
															+ thisDay
															+ '</font>');
											if (records[0].Content_Type__c == 'Only Video') {
												j$("#dialog").height("400px");
												j$('#dialog').empty();
												var iframe = j$(
														"<iframe src="
																+ records[0].VideoLink__c
																+ " width='100%' height='390' id='frameId' scrolling='no' frameborder='0'><\/iframe>")
														.appendTo('#dialog');
											}
											if (records[0].Content_Type__c == 'Flash') {
												j$("#dialog").height("400px");
												j$('#dialog').empty();
												var iframe = j$(
														"<iframe src="
																+ records[0].FlashLink__c
																+ " width='100%' height='390' id='frameId' scrolling='no' frameborder='0'><\/iframe>")
														.appendTo('#dialog');
											}
											if (records[0].Content_Type__c == 'Video And Text') {
												j$("#dialog").height("400px");
												j$('#dialog').empty();
												var iframe = j$(
														"<iframe src="
																+ records[0].VideoLink__c
																+ " width='100%' height='390' id='frameId' scrolling='no' frameborder='0'><\/iframe>")
														.appendTo('#dialog');
												var text = "<div style='height:20%; width: 100%;'>"
														+ records[0].Content__c
														+ "</div>";
												j$('#dialog').append(text);
												var contentheight = j$('#dialog')[0].scrollHeight;
												if (contentheight > 450) {
													j$("#dialog").height(
															"450px");
												} else {
													j$("#dialog").height(
															contentheight);
												}
											}
											if (records[0].Content_Type__c == 'HTML') {
												var messageText = "<div><table cellpadding='0' cellspacing='5' border='0' width='100%' height='100%'><tr><td width='150px' align='left' valign='top'>";
												if (records[0].Image__c == null) {
													messageText = messageText
															+ "<img src='/resource/1284552471000/TOTDSource/monday.jpg' width='150px'/> ";
												} else {
													if (records[0].Image__c
															.search('img') != -1) {
														messageText = messageText
																+ records[0].Image__c;
													} else {
														messageText = messageText
																+ "<img src="+records[0].Image__c+" width='150px'/> ";
													}
												}
												messageText = messageText
														+ "</td><td style='font:arial;font-family:Arial;font-size:13px;font-weight:normal;' align='left' valign='top'>";
												messageText = messageText
														+ records[0].Content__c;
												messageText = messageText
														+ "</tr></table></div>";
												j$('#dialog').empty().html(
														messageText);
												var contentheight = j$('#dialog')[0].scrollHeight;
												if (contentheight > 250) {
													j$("#dialog").height(
															"250px");
												} else {
													j$("#dialog").height(
															contentheight);
												}
											}
										} else {
											j$('#dialog').html(
													"No Message Found");
										}
									} catch (e) {
										j$('#dialog')
												.html(
														"<b>Insufficient Privileges</b><br><br>"
																+ "You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.");
									}
								});
			}
			function getActiveMesageDetails(thisDay) {
				return (sforce.connection
						.query("Select Content__c,Image__c,Content_Type__c,VideoLink__c,FlashLink__c from TOTD__c where Day__c='"
								+ thisDay + "' limit 1"));
			}