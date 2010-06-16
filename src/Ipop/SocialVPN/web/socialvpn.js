/*
Copyright (C) 2009 Pierre St Juste <ptony82@ufl.edu>, University of Florida

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

var stateXML = "";
var refresh_time = 0;
var global_status = "Offline";
var local_user;

init();

function init() {
  getState();
  loadPage();
  window.setInterval(getState, 15000);
}

function createElem(itemType, itemHTML, itemID, itemClass, containerName, 
                    functionName) {
  var elem = document.createElement(itemType);
  if (itemID != "") {
    elem.id = itemID;
  }

  if (itemClass != "") {
    elem.className = itemClass;
  }

  try {
    elem.innerHTML = itemHTML;
  } catch (err) {}

  setEvent(elem, functionName);

  if(typeof containerName == 'string') {
    var container = document.getElementById(containerName); 
    container.appendChild(elem);
  }
  else {
    containerName.appendChild(elem);
  }
  return elem;
}

function setEvent(elem, functionName) {
  if(functionName != "") {
    if(elem.addEventListener) {
      elem.addEventListener("click", functionName, false);
    }
    else if(elem.attachEvent) {
      elem.attachEvent("onclick", functionName);
    }
  }
}

function getContent(xmlElem) {
  var content;
  if(xmlElem.textContent) {
    content = xmlElem.textContent;
  }
  else if(xmlElem.text) {
    content = xmlElem.text;
  }
  return content;
}

function clearDiv(name) {
  var div_main_content = document.getElementById(name);
  div_main_content.innerHTML = "";
}

function loadPage() {
  document.title = "SocialVPN"; 
  var headElement = document.getElementsByTagName('head')[0];
  var styleSheet = document.createElement('link');
  styleSheet.setAttribute('rel', 'stylesheet');
  styleSheet.setAttribute('type', 'text/css');
  styleSheet.setAttribute('href', 'socialvpn.css');
  headElement.appendChild(styleSheet);

  document.body.innerHTML = '';
  var div_wrapper = document.createElement('div');
  div_wrapper.id = "wrapper";
  document.body.appendChild(div_wrapper);

  var header = createElem("div", "","header","", div_wrapper, "");
  var subheader = createElem("div", "", "subheader","", header, "");
  var main = createElem("div", "", "main_body", "", div_wrapper, "");
  var tmp_content = createElem("div", "", "user_content", "", main, "");
  var tmp_content = createElem("div", "", "tmp_content", "", main, "");
  var main_content = createElem("div", "", "main_content", "", main, "");
}

function loadHeader() {
  clearDiv('subheader');
  createElem("h1", "SocialVPN", "", "", "subheader", "");

  var menu = createElem("ul", "", "", "", "subheader", "");
  createElem("li", "", "status_id", "", menu, "");
  createElem("li", "Add Friend", "", "", menu, addCert);
  if(global_status == "Online") {
    createElem("li", "Logout", "login_id", "", menu, makeLogout);
  }
  else {
    createElem("li", "Login", "login_id", "", menu, loadLogin); 
  }
  setStatus(global_status);
}

function loadUser() {
  clearDiv("user_content");

  var user = stateXML.getElementsByTagName('LocalUser')[0]; 
  var uid = getContent(user.getElementsByTagName('Uid')[0]);
  var pcid = getContent(user.getElementsByTagName('PCID')[0]);
  global_status = getContent(user.getElementsByTagName('Status')[0]);
  var img_src = getContent(user.getElementsByTagName('Pic')[0]);
  var img_usr = createElem("img", "", "", "f_left", "user_content", ""); 
  img_usr.setAttribute("src", img_src);
  img_usr.setAttribute("width", "50");
  img_usr.setAttribute("height", "50");
  var innerHTML = uid + " <em>(" + pcid + ")</em>";
  createElem("h2", innerHTML, "", "", "user_content", "");
  local_user = uid;
}

function loadFriends() {
  clearDiv("main_content");
  createElem("table", "", "data_table", "", "main_content", "");

  var friends = stateXML.getElementsByTagName('SocialUser');
  for (var i = 0; i < friends.length; i++) {
    var uid = getContent(friends[i].getElementsByTagName('Uid')[0]);
    if(uid == local_user) {
      uid = "This is you";
      addFriend(friends[i], uid);
      addInfo(friends[i], uid);
    }
  }
  for (var i = 0; i < friends.length; i++) {
    var uid = getContent(friends[i].getElementsByTagName('Uid')[0]);
    if(uid != local_user) {
      addFriend(friends[i], uid);
      addInfo(friends[i], uid);
    }
  }
}

function addFriend(friend, uid) {

  var friend_td = document.getElementById(uid);
  if (friend_td == null) {
 
    var new_tr = document.createElement('tr'); 
    var new_td1 = document.createElement('td');
    var new_td2 = document.createElement('td');
    var new_td3 = document.createElement('td');
    new_td2.setAttribute('width', '100%');
  
    var block = 
      createElem("span", "Block", "", "opts_menu", new_td3, blockFriend);
    new_td3.appendChild(document.createElement('br'));
    var unblock = 
      createElem("span", "Unblock", "", "opts_menu", new_td3, unblockFriend);

    var key = getContent(friend.getElementsByTagName('Uid')[0]);
    new_td2.id = uid;
    block.key = key;
    unblock.key = key;

    var img_src = getContent(friend.getElementsByTagName('Pic')[0]);
    var img_usr = document.createElement('img');
    img_usr.setAttribute("src", img_src);
    img_usr.setAttribute("width", "30");
    img_usr.setAttribute("height", "30");
    new_td1.appendChild(img_usr);

    var info_item = createElem("span", uid, "", "f_name", new_td2, "");
    new_td2.appendChild(document.createElement('br'));

    var dtTable = document.getElementById('data_table');
    dtTable.appendChild(new_tr);
    new_tr.appendChild(new_td1);
    new_tr.appendChild(new_td2);
    new_tr.appendChild(new_td3);
  }
}

function addInfo(friend, uid) {
  var friend_td = document.getElementById(uid);
  var alias = getContent(friend.getElementsByTagName('Alias')[0]);
  var ip = getContent(friend.getElementsByTagName('IP')[0]);
  var access = getContent(friend.getElementsByTagName('Access')[0]);
  var stat = getContent(friend.getElementsByTagName('Status')[0]);
  var time = getContent(friend.getElementsByTagName('Time')[0]);

  if(access == "Block") {
    var info = "- " + alias + " - (Blocked)";
    createElem("p", info, "", "f_info", friend_td, "");
  }
  else if( stat == "Online") {
    var info = "+ " + alias + " - " + ip + " (" + stat + ")";
    createElem("p", info, "", "f_info2", friend_td, "");
  }
  else {
    var info = "- " + alias + " - (" + stat + ")";
    createElem("p", info, "", "f_info", friend_td, "");
  }
}

function cancelSubmit() {
  clearDiv('tmp_content');
}

function loadLogin() {  
  clearDiv('tmp_content');

  var message = "Password:";
  createElem("span", message, "", "f_name", "tmp_content", "");

  var pass_html = "<input id=\"data_in_pass\" type=\"password\">";
  var span_pass = createElem("span", pass_html, "", "","tmp_content", "");

  var in_butt = createElem("button", "Login", "", "", "tmp_content", 
                           submitLogin);
  in_butt.setAttribute("type", "text");
  var in_butt2 = createElem("button", "Cancel", "", "", "tmp_content", 
                            cancelSubmit);
  in_butt2.setAttribute("type", "text");
}

function submitLogin() {
  var local_user = stateXML.getElementsByTagName('LocalUser')[0]; 
  var uid = getContent(local_user.getElementsByTagName('Uid')[0]);

  var input_data ="m=jabber.login&uid=" + 
    encodeURIComponent(uid) +
    "&pass=" +    
    encodeURIComponent(document.getElementById('data_in_pass').value);    
  makeCall(input_data, 2000);
  clearDiv('tmp_content');
  setStatus("Logging in");
}

function addCert() {  
  clearDiv('tmp_content');

  var message = "Friend ID:";
  createElem("span", message, "", "f_name", "tmp_content", "");
  var id = createElem("input", "", "data_in_id", "", "tmp_content","");

  var message = "Friend certificate (base64 string):";
  createElem("span", message, "", "f_name", "tmp_content", "");
  var itext = createElem("textarea", "", "data_input", "", "tmp_content","");
  itext.setAttribute("rows", "5");
  itext.setAttribute("cols", "50");
  
  var in_butt = createElem("button", "Add Friend", "", "", "tmp_content", 
                           submitCert);
  in_butt.setAttribute("type", "text");
  
  var in_butt2 = createElem("button", "Cancel", "", "", "tmp_content", 
                            cancelSubmit);
  in_butt2.setAttribute("type", "text");
}

function submitCert() {
  var input_data ="m=add&uid=" + 
    encodeURIComponent(document.getElementById('data_in_id').value) +
    "&cert=" +    
    encodeURIComponent(document.getElementById('data_input').value);    
  makeCall(input_data, 2000);
  clearDiv('tmp_content');
}

function getState() {
  makeCall('m=getstate', 0);
}

function makeLogout() {
  setStatus("Logging out");
  makeCall('m=jabber.logout', 1000);
}

function setStatus(message) {
  var status_elem = document.getElementById('status_id');
  if (status_elem != null) {
    status_elem.innerHTML = "... " + message + " ...";
  }
}

function getKey(caller) {
  var key;  
  if(caller.key) {
    key = caller.key;
  }
  else if(event !== undefined) {
    key = event.srcElement.key;
  }
  return key;
}

function blockFriend() {
  setStatus("blocking friend");
  var postData = "m=block&uid=" + 
    encodeURIComponent(getKey(this));
  makeCall(postData, 1000);
}

function unblockFriend() {
  setStatus("unblocking friend");
  var postData = "m=unblock&uid=" + 
    encodeURIComponent(getKey(this));
  makeCall(postData, 1000);
}

function makeCall(postData, ref_time) {
  refresh_time = ref_time;
  var httpRequest;
  if(window.XMLHttpRequest) {
    httpRequest = new XMLHttpRequest();
    //httpRequest.overrideMimeType('text/xml');
  }
  else if(window.ActiveXObject) {
    httpRequest = new ActiveXObject("Microsoft.XMLHTTP");
  }
  else {
    alert("No XMLHTTP support, try another browser");
  }
  
  httpRequest.onreadystatechange = function() { 
    if(httpRequest.readyState == 4) {
      stateXML = httpRequest.responseXML;
      if(refresh_time != 0) {
        window.setTimeout(getState, refresh_time);
      }
      else {
        loadUser();
        loadHeader();
        loadFriends();
      }
    }
  };  
  httpRequest.open('POST', 'state.xml', true);
  httpRequest.setRequestHeader("Content-type", 
                               "application/x-www-form-urlencoded");
  httpRequest.setRequestHeader("Content-length", postData.length);
  httpRequest.setRequestHeader("Connection", "close");
  httpRequest.send(postData);
}

