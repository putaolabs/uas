module app.common.http;

import std.uri;
import std.stdio;
import std.conv;
import std.json;
import std.array;
import std.string;
import std.format;
import std.regex;
import std.base64;
import std.random;
import std.datetime;
import std.typecons;
import std.algorithm;
import std.digest.md;
import std.digest.sha;
import Curl = std.net.curl;
import etc.c.curl : CurlOption;
import std.algorithm.searching;
import std.experimental.logger;
import core.stdc.time;

import app.common;
import app.exception;

class HTTPHelper
{
	public static ubyte[] post(string ctype = "application/x-www-form-urlencoded", long tmout = 30)(string requestURL,ubyte[] data)
	{
		log("POST URL : ",requestURL);
		log("POST DATA : ",cast(string)data);

		ubyte[] result;

		auto http = Curl.HTTP();
		http.handle.set(CurlOption.ssl_verifyhost, 0);
		http.handle.set(CurlOption.ssl_verifypeer, 0);
		http.method = Curl.HTTP.Method.post;
		http.url = requestURL;
		http.setPostData(data, ctype);
		http.operationTimeout = dur!"seconds"(tmout);
		http.onReceive = (ubyte[] data) {result~=data; return data.length; };

		http.perform();

		log("POST RESULT : ",cast(string)result);
		return result;
	}

	public static ubyte[] post(string ctype = "application/x-www-form-urlencoded", long tmout = 30)(string requestURL,string[string] postData)
	{
		string fpostData = formatPostData(postData);
		ubyte[] upostData = cast(ubyte[])fpostData;
		return post!(ctype,tmout)(requestURL,upostData);
	}

	public static ubyte[] post(string ctype = "application/x-www-form-urlencoded", long tmout = 30)(string requestURL,JSONValue postData)
	{
		string fpostData = postData.toString;
		ubyte[] upostData = cast(ubyte[])fpostData;
		return post!(ctype,tmout)(requestURL,upostData);
	}

	public static JSONValue unsafePost(string requestURL,string[string] postData)
	{
		JSONValue jsonReqResult;
		ubyte[] reqResult = post(requestURL,postData);
		jsonReqResult = parseJSON(cast(string)reqResult);
		return jsonReqResult;
	}
	
	public static string formatPostData(string[string] postData)
	{
		string result;
		foreach(key,value;postData)
		{
			result ~= key ~ "=" ~ encodeComponent(value) ~ "&";
		}
		//string endResult = encodeComponent(result);
		return result;
	}


	public static string aa_sorted_sign(string[string] data, string sign_key = string.init)
	{
		auto sortbb= aa_sort(data);
		string[] need_md5;
		foreach( cc ; sortbb)
		{
			if(cc[0] == "sign")
			{
				continue;
			}
			need_md5 ~= cc[0] ~ "=" ~ encodeComponent(cc[1]);
		}
		return toHexString(md5Of(need_md5.join('&') ~ sign_key)).toLower();
	}

	public static Tuple!(K, V)[] aa_sort(K, V)(V[K] aa)
	{
		typeof(return) r=[];
		foreach(k,v;aa) r~=tuple(k,v);
		sort!q{a[0]<b[0]}(r);
		return r;
	}
}
