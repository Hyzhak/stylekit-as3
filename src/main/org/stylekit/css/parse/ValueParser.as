package org.stylekit.css.parse
{
	
	import org.utilkit.util.StringUtil;
	import org.stylekit.css.selector.MediaSelector;
	
	import org.stylekit.css.value.SizeValue;
	import org.stylekit.css.value.EdgeCompoundValue;
	
	/**
	* The <code>ValueParser</code> class provides utility methods for parsing CSS property values of various types.
	*/
	public class ValueParser
	{
		
		public function ValueParser()
		{
			
		}
		
		/**
		* Parses a four-way sizing value such as may be used for padding, margin etc. and returns an EdgeCompoundValue.
		*/
		public function parseEdgeSizeCompoundValue(str:String):EdgeCompoundValue
		{
			var sizeStrings:Vector.<String> = this.parseSpaceDelimitedString(str);
			var cVal:EdgeCompoundValue = new EdgeCompoundValue();
			
			var sizeValues:Vector.<SizeValue> = new Vector.<SizeValue>();
			for(var i:uint = 0; i < sizeStrings.length; i++)
			{
				sizeValues.push(this.parseSizeValue(sizeStrings[i]));
			}
			
			switch(sizeValues.length)
			{
				case 1:
					// all
					cVal.leftValue = cVal.rightValue = cVal.topValue = cVal.bottomValue = sizeValues[0];
					break;
				case 2:
					// top+bottom, left+right
					cVal.topValue = cVal.bottomValue = sizeValues[0];
					cVal.leftValue = cVal.rightValue = sizeValues[1];
					break;
				case 3: 
					// top, left+right, bottom
					cVal.topValue = sizeValues[0];
					cVal.leftValue = cVal.rightValue = sizeValues[1];
					cVal.bottomValue = sizeValues[2];
					break;
				case 4:
					// top, right, bottom, left
					cVal.topValue = sizeValues[0];
					cVal.rightValue = sizeValues[1];
					cVal.bottomValue = sizeValues[2];
					cVal.leftValue = sizeValues[3];
					break;
			}
			
			return cVal;
		}
		
		public function parseSizeValue(str:String):SizeValue
		{
			str = StringUtil.trim(str.toLowerCase());
			var sVal:SizeValue = new SizeValue();
			var unitPattern:RegExp = new RegExp("[%a-zA-Z]+");
			var unitIndex:int = str.search(unitPattern);

			sVal.value = parseFloat(str);
			
			if(unitIndex >= 0)
			{
				sVal.units = str.substring(unitIndex);
			}
			
			return sVal;
		}
		
		/**
		* Accepts an argument string from a CSS @import statement and parses it into an array containing a
		* URLValue object and a MediaSelector.
		*/ 
		public function parseImportArguments(importArgs:String):Array
		{
			var result:Array = [];
			var urlParserResult:Array = this.parseURLToken(importArgs);
			var mediaSelectorParserResult:MediaSelector = this.parseMediaSelector(importArgs.slice(urlParserResult[1]));
			
			return [urlParserResult[0], mediaSelectorParserResult];
		}
		
		/**
		* Accepts a comma-delimited set of media types and produces a matching MediaSelector object.
		*/
		public function parseMediaSelector(str:String):MediaSelector
		{
			var mSel:MediaSelector = new MediaSelector();
			var mediaTypes:Vector.<String> = this.parseCommaDelimitedString(str);

			if(mediaTypes.length == 0)
			{
				return null;
			}
			
			for(var m:uint = 0; m < mediaTypes.length; m++)
			{
				mSel.addMedia(mediaTypes[m]);
			}
			return mSel;
		}
		
		/**
		* Accepts a string such as 'url("foo.css")' and return the URL component as well as the length of the parsed token.
		* e.g. url("foo.css") will parse to ["foo.css", 14]
		*/
		public function parseURLToken(importArgs:String):Array
		{
			// Walk the string until either a bracket or a quote is found
			var openBracketFound:Boolean = false;
			var openStringFound:Boolean = false;
			var closeBracketFound:Boolean = false;
			var closeStringFound:Boolean = false;
			var openStringChar:String;
			
			var token:String = "";
			var count:uint = 0;
			
			for(var i:uint=0; i < importArgs.length; i++)
			{
				var char:String = importArgs.charAt(i);
				
				
				
				if(char == "(") 
				{
					openBracketFound = true;
				}
				else if(!openStringFound && (char == "'" || char == "\""))
				{
					openStringFound = true;
					openStringChar = char;
				}
				else if(char == ")") 
				{
					closeBracketFound = true;
				}
				else if(openStringFound && char == openStringChar)
				{
					closeStringFound = true;
				}
				else
				{
					if(openBracketFound || openStringFound)
					{
						token += char;
					}
				}
				
				if((!openBracketFound && openStringFound && closeStringFound) || (!openStringFound && openBracketFound && closeBracketFound) || (openStringFound && closeStringFound && openBracketFound && closeBracketFound))
				{
					// If there was no open bracket but there was a quote and we've found the open and close quotes
					// if there was no quote but we've found both brackets
					// if there was a bracket and a quote and we've found both ends
					count = i+1;
					break;
				}
			}
			
			return [token, count];
		}
		
		/**
		* Extracts the url string from a CSS url statement. Convenience equivalent of parseURLToken(string)[0].
		*/
		public function extractURL(str:String):String
		{
			return (this.parseURLToken(str)[0] as String);
		}
		
		/**
		* Parses a space-delimited CSS property string and returns the resulting vector of individual string objects.
		* ignores spaces that occur within brackets or quotes.
		*/
		public function parseSpaceDelimitedString(str:String):Vector.<String>
		{
			str = StringUtil.trim(str);
			var result:Vector.<String> = new Vector.<String>();
			var tokenOpened:Boolean = false;
			var token:String = "";
			
			var bracketDepth:uint = 0;
			var quoteStack:Vector.<String> = new Vector.<String>();
			
			for(var i:uint=0; i <= str.length; i++) // loop deliberately overruns
			{
				var char:String;
				if(i < str.length) char = str.charAt(i);
				else char = "END";
				
				
				// Decide whether to open or close a token
				if(char == " " || char == "END")
				{
					if(tokenOpened && bracketDepth <= 0 && quoteStack.length == 0)
					{
						// Close the token
						tokenOpened = false;
						result.push(token);
						token = "";
					}
					else
					{
						// Consider part of the token
						tokenOpened = true;
						token += char;
					}
				}
				else
				{
					tokenOpened = true;
					token += char;
				}
				
				if(char == "(")
				{
					bracketDepth++;
				}
				else if(char == ")")
				{
					bracketDepth = Math.max(0, bracketDepth-1);
				}
				else if(char == "'" || char == "\"")
				{
					if(quoteStack.length > 0 && char == quoteStack[quoteStack.length-1])
					{
						// Found a closing quote
						quoteStack.pop();
					}
					else
					{
						quoteStack.push(char);
					}
				}
			}
			
			return result;
		}
		
		/**
		* Parses a comma-delimited string into a vector of strings, trimming the whitespace from each.
		* e.g. "foo,bar, car, baz,, faz,,  bat, " > vector containing foo,bar,car,baz,faz,bat
		*/
		public function parseCommaDelimitedString(str:String):Vector.<String>
		{
			var spl:Array = str.split(",");
			var vec:Vector.<String> = new Vector.<String>();
			for(var i:uint=0; i<spl.length; i++)
			{
				var strp:String = StringUtil.trim(spl[i]);
				if(strp.length > 0)
				{
					vec.push(strp);
				}
			}
			return vec;
		}
		
	}
	
}