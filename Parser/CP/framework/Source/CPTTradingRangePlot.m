#import <stdlib.h>
#import "CPTMutableNumericData.h"
#import "CPTNumericData.h"
#import "CPTTradingRangePlot.h"
#import "CPTLegend.h"
#import "CPTLineStyle.h"
#import "CPTPlotArea.h"
#import "CPTPlotSpace.h"
#import "CPTPlotSpaceAnnotation.h"
#import "CPTExceptions.h"
#import "CPTUtilities.h"
#import "CPTXYPlotSpace.h"
#import "CPTPlotSymbol.h"
#import "CPTFill.h"
#import "CPTColor.h"

NSString * const CPTTradingRangePlotBindingXValues = @"xValues";			///< X values.
NSString * const CPTTradingRangePlotBindingOpenValues = @"openValues";	///< Open price values.
NSString * const CPTTradingRangePlotBindingHighValues = @"highValues";	///< High price values.
NSString * const CPTTradingRangePlotBindingLowValues = @"lowValues";		///< Low price values.
NSString * const CPTTradingRangePlotBindingCloseValues = @"closeValues";	///< Close price values.

/**	@cond */
@interface CPTTradingRangePlot ()

@property (nonatomic, readwrite, copy) CPTMutableNumericData *xValues;
@property (nonatomic, readwrite, copy) CPTMutableNumericData *openValues;
@property (nonatomic, readwrite, copy) CPTMutableNumericData *highValues;
@property (nonatomic, readwrite, copy) CPTMutableNumericData *lowValues;
@property (nonatomic, readwrite, copy) CPTMutableNumericData *closeValues;

-(void)drawCandleStickInContext:(CGContextRef)context x:(CGFloat)x open:(CGFloat)open close:(CGFloat)close high:(CGFloat)high low:(CGFloat)low;
-(void)drawOHLCInContext:(CGContextRef)context x:(CGFloat)x open:(CGFloat)open close:(CGFloat)close high:(CGFloat)high low:(CGFloat)low;

@end
/**	@endcond */

#pragma mark -

/** @brief A trading range financial plot.
 **/
@implementation CPTTradingRangePlot

@dynamic xValues;
@dynamic openValues;
@dynamic highValues;
@dynamic lowValues;
@dynamic closeValues;

/** @property lineStyle
 *	@brief The line style used to draw candlestick or OHLC symbols.
 **/
@synthesize lineStyle;

/** @property increaseLineStyle
 *	@brief The line style used to outline candlestick symbols when close >= open. If nil, will use lineStyle instead.
 **/
@synthesize increaseLineStyle;

/** @property decreaseLineStyle
 *	@brief The line style used to outline candlestick symbols when close < open. If nil, will use lineStyle instead.
 **/
@synthesize decreaseLineStyle;

/** @property increaseFill
 *	@brief The fill used with a candlestick plot when close >= open.
 **/
@synthesize increaseFill;

/** @property decreaseFill
 *	@brief The fill used with a candlestick plot when close < open.
 **/
@synthesize decreaseFill;

/** @property plotStyle
 *	@brief The style of trading range plot drawn.
 **/
@synthesize plotStyle;

/** @property barWidth
 *	@brief The width of bars in candlestick plots (view coordinates).
 **/
@synthesize barWidth;

/** @property stickLength
 *	@brief The length of close and open sticks on OHLC plots (view coordinates).
 **/
@synthesize stickLength;

/** @property barCornerRadius
 *	@brief The corner radius used for candlestick plots.
 *  Defaults to 0.0.
 **/
@synthesize barCornerRadius;

#pragma mark -
#pragma mark init/dealloc

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#else
+(void)initialize
{
	if ( self == [CPTTradingRangePlot class] ) {
		[self exposeBinding:CPTTradingRangePlotBindingXValues];	
		[self exposeBinding:CPTTradingRangePlotBindingOpenValues];	
		[self exposeBinding:CPTTradingRangePlotBindingHighValues];	
		[self exposeBinding:CPTTradingRangePlotBindingLowValues];	
		[self exposeBinding:CPTTradingRangePlotBindingCloseValues];	
	}
}
#endif

-(id)initWithFrame:(CGRect)newFrame
{
	if ( (self = [super initWithFrame:newFrame]) ) {
        plotStyle = CPTTradingRangePlotStyleOHLC;
		lineStyle = [[CPTLineStyle alloc] init];
		increaseLineStyle = nil;
		decreaseLineStyle = nil;
        increaseFill = [(CPTFill *)[CPTFill alloc] initWithColor:[CPTColor whiteColor]];
        decreaseFill = [(CPTFill *)[CPTFill alloc] initWithColor:[CPTColor blackColor]];
        barWidth = 5.0;
        stickLength = 3.0;
        barCornerRadius = 0.0;
		
		self.labelField = CPTTradingRangePlotFieldClose;
	}
	return self;
}

-(id)initWithLayer:(id)layer
{
	if ( (self = [super initWithLayer:layer]) ) {
		CPTTradingRangePlot *theLayer = (CPTTradingRangePlot *)layer;
		
		plotStyle = theLayer->plotStyle;
		lineStyle = [theLayer->lineStyle retain];
		increaseLineStyle = [theLayer->increaseLineStyle retain];
		decreaseLineStyle = [theLayer->decreaseLineStyle retain];
		increaseFill = [theLayer->increaseFill retain];
		decreaseFill = [theLayer->decreaseFill retain];
		barWidth = theLayer->barWidth;
		stickLength = theLayer->stickLength;
		barCornerRadius = theLayer->barCornerRadius;
	}
	return self;
}

-(void)dealloc
{
	[lineStyle release];
	[increaseLineStyle release];
	[decreaseLineStyle release];
	[increaseFill release];
	[decreaseFill release];
    
	[super dealloc];
}

#pragma mark -
#pragma mark Data Loading

-(void)reloadDataInIndexRange:(NSRange)indexRange
{	 
	[super reloadDataInIndexRange:indexRange];
	
	if ( self.dataSource ) {
		id newXValues = [self numbersFromDataSourceForField:CPTTradingRangePlotFieldX recordIndexRange:indexRange];
		[self cacheNumbers:newXValues forField:CPTTradingRangePlotFieldX atRecordIndex:indexRange.location];
		id newOpenValues = [self numbersFromDataSourceForField:CPTTradingRangePlotFieldOpen recordIndexRange:indexRange];
		[self cacheNumbers:newOpenValues forField:CPTTradingRangePlotFieldOpen atRecordIndex:indexRange.location];
		id newHighValues = [self numbersFromDataSourceForField:CPTTradingRangePlotFieldHigh recordIndexRange:indexRange];
		[self cacheNumbers:newHighValues forField:CPTTradingRangePlotFieldHigh atRecordIndex:indexRange.location];
		id newLowValues = [self numbersFromDataSourceForField:CPTTradingRangePlotFieldLow recordIndexRange:indexRange];
		[self cacheNumbers:newLowValues forField:CPTTradingRangePlotFieldLow atRecordIndex:indexRange.location];
		id newCloseValues = [self numbersFromDataSourceForField:CPTTradingRangePlotFieldClose recordIndexRange:indexRange];
		[self cacheNumbers:newCloseValues forField:CPTTradingRangePlotFieldClose atRecordIndex:indexRange.location];
	}
	else {
		self.xValues = nil;
		self.openValues = nil;
		self.highValues = nil;
		self.lowValues = nil;
		self.closeValues = nil;
	}
}

#pragma mark -
#pragma mark Drawing

-(void)renderAsVectorInContext:(CGContextRef)theContext
{
	if ( self.hidden ) return;
	
    CPTMutableNumericData *locations = [self cachedNumbersForField:CPTTradingRangePlotFieldX];
    CPTMutableNumericData *opens = [self cachedNumbersForField:CPTTradingRangePlotFieldOpen];
	CPTMutableNumericData *highs = [self cachedNumbersForField:CPTTradingRangePlotFieldHigh];
	CPTMutableNumericData *lows = [self cachedNumbersForField:CPTTradingRangePlotFieldLow];
	CPTMutableNumericData *closes = [self cachedNumbersForField:CPTTradingRangePlotFieldClose];
	
	NSUInteger sampleCount = locations.numberOfSamples;
	if ( sampleCount == 0 ) return;
   	if ( opens == nil || highs == nil|| lows == nil|| closes == nil ) return;
    
	if ( (opens.numberOfSamples != sampleCount) || (highs.numberOfSamples != sampleCount) || (lows.numberOfSamples != sampleCount) || (closes.numberOfSamples != sampleCount) ) {
		[NSException raise:CPTException format:@"Mismatching number of data values in trading range plot"];
	}
	
	[super renderAsVectorInContext:theContext];
    [self.lineStyle setLineStyleInContext:theContext];
	
    CGPoint openPoint, highPoint, lowPoint, closePoint;
    const CPTCoordinate independentCoord = CPTCoordinateX;
    const CPTCoordinate dependentCoord = CPTCoordinateY;
	
	CPTPlotArea *thePlotArea = self.plotArea;
	CPTPlotSpace *thePlotSpace = self.plotSpace;
	CPTTradingRangePlotStyle thePlotStyle = self.plotStyle;
	
    if ( self.doublePrecisionCache ) {
        const double *locationBytes = (const double *)locations.data.bytes;
        const double *openBytes = (const double *)opens.data.bytes;
        const double *highBytes = (const double *)highs.data.bytes;
        const double *lowBytes = (const double *)lows.data.bytes;
        const double *closeBytes = (const double *)closes.data.bytes;
		
        for ( NSUInteger i = 0; i < sampleCount; i++ ) {
            double plotPoint[2];
            plotPoint[independentCoord] = *locationBytes++;
			if ( isnan(plotPoint[independentCoord]) ) {
				openBytes++;
				highBytes++;
				lowBytes++;
				closeBytes++;
				continue;
			}
			
			// open point
			plotPoint[dependentCoord] = *openBytes++;
			if ( isnan(plotPoint[dependentCoord]) ) {
				openPoint = CGPointMake(NAN, NAN);
			}
			else {
				openPoint = [self convertPoint:[thePlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint] fromLayer:thePlotArea];
			}
			
			// high point
			plotPoint[dependentCoord] = *highBytes++;
			if ( isnan(plotPoint[dependentCoord]) ) {
				highPoint = CGPointMake(NAN, NAN);
			}
			else {
				highPoint = [self convertPoint:[thePlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint] fromLayer:thePlotArea];
			}
			
			// low point
			plotPoint[dependentCoord] = *lowBytes++;
			if ( isnan(plotPoint[dependentCoord]) ) {
				lowPoint = CGPointMake(NAN, NAN);
			}
			else {
				lowPoint = [self convertPoint:[thePlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint] fromLayer:thePlotArea];
			}
			
			// close point
			plotPoint[dependentCoord] = *closeBytes++;
			if ( isnan(plotPoint[dependentCoord]) ) {
				closePoint = CGPointMake(NAN, NAN);
			}
			else {
				closePoint = [self convertPoint:[thePlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint] fromLayer:thePlotArea];
			}
			
			CGFloat xCoord = openPoint.x;
			if ( isnan(xCoord) ) {
				xCoord = highPoint.x;
			}
			else if ( isnan(xCoord) ) {
				xCoord = lowPoint.x;
			}
			else if ( isnan(xCoord) ) {
				xCoord = closePoint.x;
			}
			
			if ( !isnan(xCoord) ) {
				// Draw
				switch ( thePlotStyle ) {
					case CPTTradingRangePlotStyleOHLC:
						[self drawOHLCInContext:theContext x:xCoord open:openPoint.y close:closePoint.y high:highPoint.y low:lowPoint.y];
						break;
					case CPTTradingRangePlotStyleCandleStick:
						[self drawCandleStickInContext:theContext x:xCoord open:openPoint.y close:closePoint.y high:highPoint.y low:lowPoint.y];
						break;
					default:
						[NSException raise:CPTException format:@"Invalid plot style in renderAsVectorInContext"];
						break;
				}
			}
		}
    }
    else {
        const NSDecimal *locationBytes = (const NSDecimal *)locations.data.bytes;
        const NSDecimal *openBytes = (const NSDecimal *)opens.data.bytes;
        const NSDecimal *highBytes = (const NSDecimal *)highs.data.bytes;
        const NSDecimal *lowBytes = (const NSDecimal *)lows.data.bytes;
        const NSDecimal *closeBytes = (const NSDecimal *)closes.data.bytes;
		
        for ( NSUInteger i = 0; i < sampleCount; i++ ) {
			NSDecimal plotPoint[2];
            plotPoint[independentCoord] = *locationBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[independentCoord]) ) {
				openBytes++;
				highBytes++;
				lowBytes++;
				closeBytes++;
				continue;
			}
			
			// open point
			plotPoint[dependentCoord] = *openBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[dependentCoord]) ) {
				openPoint = CGPointMake(NAN, NAN);
			}
			else {
				openPoint = [self convertPoint:[thePlotSpace plotAreaViewPointForPlotPoint:plotPoint] fromLayer:thePlotArea];
			}
			
			// high point
			plotPoint[dependentCoord] = *highBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[dependentCoord]) ) {
				highPoint = CGPointMake(NAN, NAN);
			}
			else {
				highPoint = [self convertPoint:[thePlotSpace plotAreaViewPointForPlotPoint:plotPoint] fromLayer:thePlotArea];
			}
			
			// low point
			plotPoint[dependentCoord] = *lowBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[dependentCoord]) ) {
				lowPoint = CGPointMake(NAN, NAN);
			}
			else {
				lowPoint = [self convertPoint:[thePlotSpace plotAreaViewPointForPlotPoint:plotPoint] fromLayer:thePlotArea];
			}
			
			// close point
			plotPoint[dependentCoord] = *closeBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[dependentCoord]) ) {
				closePoint = CGPointMake(NAN, NAN);
			}
			else {
				closePoint = [self convertPoint:[thePlotSpace plotAreaViewPointForPlotPoint:plotPoint] fromLayer:thePlotArea];
			}
			
			CGFloat xCoord = openPoint.x;
			if ( isnan(xCoord) ) {
				xCoord = highPoint.x;
			}
			else if ( isnan(xCoord) ) {
				xCoord = lowPoint.x;
			}
			else if ( isnan(xCoord) ) {
				xCoord = closePoint.x;
			}
			
			if ( !isnan(xCoord) ) {
				// Draw
				switch ( thePlotStyle ) {
					case CPTTradingRangePlotStyleOHLC:
						[self drawOHLCInContext:theContext x:xCoord open:openPoint.y close:closePoint.y high:highPoint.y low:lowPoint.y];
						break;
					case CPTTradingRangePlotStyleCandleStick:
						[self drawCandleStickInContext:theContext x:xCoord open:openPoint.y close:closePoint.y high:highPoint.y low:lowPoint.y];
						break;
					default:
						[NSException raise:CPTException format:@"Invalid plot style in renderAsVectorInContext"];
						break;
				}
			}
		}
    }	
}

-(void)drawCandleStickInContext:(CGContextRef)context x:(CGFloat)x open:(CGFloat)open close:(CGFloat)close high:(CGFloat)high low:(CGFloat)low
{
 	const CGFloat halfBarWidth = 0.5 * self.barWidth;
	CPTFill *currentBarFill = nil;
	CPTLineStyle *theBorderLineStyle = nil;
	if ( !isnan(open) && !isnan(close) ) {
        if (open < close ) {
			theBorderLineStyle = self.increaseLineStyle;
			if ( !theBorderLineStyle ) {
				theBorderLineStyle = self.lineStyle;
			}
			currentBarFill = self.increaseFill;
		}
		else if ( open > close ) {
			theBorderLineStyle = self.decreaseLineStyle;
			if ( !theBorderLineStyle ) {
				theBorderLineStyle = self.lineStyle;
			}
			currentBarFill = self.decreaseFill;
		}
		else {
			theBorderLineStyle = self.lineStyle;
			currentBarFill = [CPTFill fillWithColor:theBorderLineStyle.lineColor];
		}
	}
	[theBorderLineStyle setLineStyleInContext:context];
	
	// high - low only
	if ( !isnan(high) && !isnan(low) && (isnan(open) || isnan(close)) ) {
		CGPoint alignedHighPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, high));
		CGPoint alignedLowPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, low));
		
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathMoveToPoint(path, NULL, alignedHighPoint.x, alignedHighPoint.y);
		CGPathAddLineToPoint(path, NULL, alignedLowPoint.x, alignedLowPoint.y);
		
		CGContextBeginPath(context);
		CGContextAddPath(context, path);
		CGContextStrokePath(context);
		
		CGPathRelease(path);
	}
	
	// open-close
	if ( !isnan(open) && !isnan(close) ) {
		if ( currentBarFill || theBorderLineStyle ) {
			CGFloat radius = MIN(self.barCornerRadius, halfBarWidth);
			radius = MIN(radius, ABS(close - open));
			
			CGPoint alignedPoint1 = CPTAlignPointToUserSpace(context, CGPointMake(x + halfBarWidth, open));
			CGPoint alignedPoint2 = CPTAlignPointToUserSpace(context, CGPointMake(x + halfBarWidth, close));
			CGPoint alignedPoint3 = CPTAlignPointToUserSpace(context, CGPointMake(x, close));
			CGPoint alignedPoint4 = CPTAlignPointToUserSpace(context, CGPointMake(x - halfBarWidth, close));
			CGPoint alignedPoint5 = CPTAlignPointToUserSpace(context, CGPointMake(x - halfBarWidth, open));
            
            if ( open == close ) {
                // #285 Draw a cross with open/close values marked
                const CGFloat halfLineWidth = 0.5 * self.lineStyle.lineWidth;
                
                alignedPoint1.y -= halfLineWidth;
                alignedPoint2.y += halfLineWidth;
                alignedPoint3.y += halfLineWidth;
                alignedPoint4.y += halfLineWidth;
                alignedPoint5.y -= halfLineWidth;
            }
			
			CGMutablePathRef path = CGPathCreateMutable();
			CGPathMoveToPoint(path, NULL, alignedPoint1.x, alignedPoint1.y);
			CGPathAddArcToPoint(path, NULL, alignedPoint2.x, alignedPoint2.y, alignedPoint3.x, alignedPoint3.y, radius);
			CGPathAddArcToPoint(path, NULL, alignedPoint4.x, alignedPoint4.y, alignedPoint5.x, alignedPoint5.y, radius);
			CGPathAddLineToPoint(path, NULL, alignedPoint5.x, alignedPoint5.y);
			CGPathCloseSubpath(path);
			
			if ( currentBarFill ) {
				CGContextBeginPath(context);
				CGContextAddPath(context, path);
				[currentBarFill fillPathInContext:context]; 
			}
			
			if ( theBorderLineStyle ) {
				if ( !isnan(low) ) {
					if ( low < MIN(open, close) ) {
						CGPoint alignedStartPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, MIN(open, close)));
						CGPoint alignedLowPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, low));
						
						CGPathMoveToPoint(path, NULL, alignedStartPoint.x, alignedStartPoint.y);
						CGPathAddLineToPoint(path, NULL, alignedLowPoint.x, alignedLowPoint.y);
					}
				}
				if ( !isnan(high) ) {
					if ( high > MAX(open, close) ) {
						CGPoint alignedStartPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, MAX(open, close)));
						CGPoint alignedHighPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, high));
						
						CGPathMoveToPoint(path, NULL, alignedStartPoint.x, alignedStartPoint.y);
						CGPathAddLineToPoint(path, NULL, alignedHighPoint.x, alignedHighPoint.y);
					}
				}
				CGContextBeginPath(context);
				CGContextAddPath(context, path);
				CGContextStrokePath(context);
			}
			
			CGPathRelease(path);
		}
	}
}

-(void)drawOHLCInContext:(CGContextRef)context x:(CGFloat)x open:(CGFloat)open close:(CGFloat)close high:(CGFloat)high low:(CGFloat)low
{
	CGFloat theStickLength = self.stickLength;
    CGMutablePathRef path = CGPathCreateMutable();
	
	// high-low
	if ( !isnan(high) && !isnan(low) ) {
		CGPoint alignedHighPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, high));
		CGPoint alignedLowPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, low));
		CGPathMoveToPoint(path, NULL, alignedHighPoint.x, alignedHighPoint.y);
		CGPathAddLineToPoint(path, NULL, alignedLowPoint.x, alignedLowPoint.y);
	}
	
	// open
	if ( !isnan(open) ) {
		CGPoint alignedOpenStartPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, open));
		CGPoint alignedOpenEndPoint = CPTAlignPointToUserSpace(context, CGPointMake(x - theStickLength, open)); // left side
		CGPathMoveToPoint(path, NULL, alignedOpenStartPoint.x, alignedOpenStartPoint.y);
		CGPathAddLineToPoint(path, NULL, alignedOpenEndPoint.x, alignedOpenEndPoint.y);
	}
	
	// close
	if ( !isnan(close) ) {
		CGPoint alignedCloseStartPoint = CPTAlignPointToUserSpace(context, CGPointMake(x, close));
		CGPoint alignedCloseEndPoint = CPTAlignPointToUserSpace(context, CGPointMake(x + theStickLength, close)); // right side
		CGPathMoveToPoint(path, NULL, alignedCloseStartPoint.x, alignedCloseStartPoint.y);
		CGPathAddLineToPoint(path, NULL, alignedCloseEndPoint.x, alignedCloseEndPoint.y);
	}
	
	CGContextBeginPath(context);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
	CGPathRelease(path);
}

-(void)drawSwatchForLegend:(CPTLegend *)legend atIndex:(NSUInteger)index inRect:(CGRect)rect inContext:(CGContextRef)context
{
	[super drawSwatchForLegend:legend atIndex:index inRect:rect inContext:context];
    [self.lineStyle setLineStyleInContext:context];
	
	switch ( self.plotStyle ) {
		case CPTTradingRangePlotStyleOHLC:
			[self drawOHLCInContext:context
								  x:CGRectGetMidX(rect)
							   open:CGRectGetMinY(rect) + rect.size.height / 3.0
							  close:CGRectGetMinY(rect) + rect.size.height * 2.0 / 3.0
							   high:CGRectGetMaxY(rect) 
								low:CGRectGetMinY(rect)];
			break;
			
		case CPTTradingRangePlotStyleCandleStick:
			[self drawCandleStickInContext:context
										 x:CGRectGetMidX(rect)
									  open:CGRectGetMinY(rect) + rect.size.height / 3.0
									 close:CGRectGetMinY(rect) + rect.size.height * 2.0 / 3.0
									  high:CGRectGetMaxY(rect) 
									   low:CGRectGetMinY(rect)];
			break;
			
		default:
			break;
	}
}

#pragma mark -
#pragma mark Fields

-(NSUInteger)numberOfFields 
{
    return 5;
}

-(NSArray *)fieldIdentifiers 
{
    return [NSArray arrayWithObjects:
			[NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldX], 
			[NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldOpen], 
			[NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldClose], 
			[NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldHigh], 
			[NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldLow], 
			nil];
}

-(NSArray *)fieldIdentifiersForCoordinate:(CPTCoordinate)coord 
{
	NSArray *result = nil;
	switch (coord) {
        case CPTCoordinateX:
            result = [NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldX]];
            break;
        case CPTCoordinateY:
            result = [NSArray arrayWithObjects:
					  [NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldOpen], 
					  [NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldLow], 
					  [NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldHigh], 
					  [NSNumber numberWithUnsignedInt:CPTTradingRangePlotFieldClose], 
					  nil];
            break;
        default:
        	[NSException raise:CPTException format:@"Invalid coordinate passed to fieldIdentifiersForCoordinate:"];
            break;
    }
    return result;
}

#pragma mark -
#pragma mark Data Labels

-(void)positionLabelAnnotation:(CPTPlotSpaceAnnotation *)label forIndex:(NSUInteger)index
{
	BOOL positiveDirection = YES;
	CPTPlotRange *yRange = [self.plotSpace plotRangeForCoordinate:CPTCoordinateY];
	if ( CPTDecimalLessThan(yRange.length, CPTDecimalFromInteger(0)) ) {
		positiveDirection = !positiveDirection;
	}
	
	NSNumber *xValue = [self cachedNumberForField:CPTTradingRangePlotFieldX recordIndex:index];
	NSNumber *yValue;
	NSArray *yValues = [NSArray arrayWithObjects:[self cachedNumberForField:CPTTradingRangePlotFieldOpen recordIndex:index],
						[self cachedNumberForField:CPTTradingRangePlotFieldClose recordIndex:index],
						[self cachedNumberForField:CPTTradingRangePlotFieldHigh recordIndex:index],
						[self cachedNumberForField:CPTTradingRangePlotFieldLow recordIndex:index], nil];
	NSArray *yValuesSorted = [yValues sortedArrayUsingSelector:@selector(compare:)];
	if ( positiveDirection ) {
		yValue = [yValuesSorted lastObject];
	}
	else {
		yValue = [yValuesSorted objectAtIndex:0];
	}
	
	label.anchorPlotPoint = [NSArray arrayWithObjects:xValue, yValue, nil];
	
	if ( positiveDirection ) {
		label.displacement = CGPointMake(0.0, self.labelOffset);
	}
	else {
		label.displacement = CGPointMake(0.0, -self.labelOffset);
	}
	
	label.contentLayer.hidden = isnan([xValue doubleValue]) || isnan([yValue doubleValue]);
}

#pragma mark -
#pragma mark Accessors

-(void)setPlotStyle:(CPTTradingRangePlotStyle)newPlotStyle
{
	if ( plotStyle != newPlotStyle ) {
		plotStyle = newPlotStyle;
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setLineStyle:(CPTLineStyle *)newLineStyle
{
	if ( lineStyle != newLineStyle ) {
		[lineStyle release];
		lineStyle = [newLineStyle copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setIncreaseLineStyle:(CPTLineStyle *)newLineStyle
{
	if ( increaseLineStyle != newLineStyle ) {
		[increaseLineStyle release];
		increaseLineStyle = [newLineStyle copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setDecreaseLineStyle:(CPTLineStyle *)newLineStyle
{
	if ( decreaseLineStyle != newLineStyle ) {
		[decreaseLineStyle release];
		decreaseLineStyle = [newLineStyle copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setIncreaseFill:(CPTFill *)newFill
{
	if ( increaseFill != newFill ) {
		[increaseFill release];
		increaseFill = [newFill copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setDecreaseFill:(CPTFill *)newFill
{
	if ( decreaseFill != newFill ) {
		[decreaseFill release];
		decreaseFill = [newFill copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setBarWidth:(CGFloat)newWidth
{
	if ( barWidth != newWidth ) {
		barWidth = newWidth;
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setStickLength:(CGFloat)newLength
{
	if ( stickLength != newLength ) {
		stickLength = newLength;
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setXValues:(CPTMutableNumericData *)newValues 
{
    [self cacheNumbers:newValues forField:CPTTradingRangePlotFieldX];
}

-(CPTMutableNumericData *)xValues 
{
    return [self cachedNumbersForField:CPTTradingRangePlotFieldX];
}

-(CPTMutableNumericData *)openValues 
{
    return [self cachedNumbersForField:CPTTradingRangePlotFieldOpen];
}

-(void)setOpenValues:(CPTMutableNumericData *)newValues 
{
    [self cacheNumbers:newValues forField:CPTTradingRangePlotFieldOpen];
}

-(CPTMutableNumericData *)highValues 
{
    return [self cachedNumbersForField:CPTTradingRangePlotFieldHigh];
}

-(void)setHighValues:(CPTMutableNumericData *)newValues 
{
    [self cacheNumbers:newValues forField:CPTTradingRangePlotFieldHigh];
}

-(CPTMutableNumericData *)lowValues 
{
    return [self cachedNumbersForField:CPTTradingRangePlotFieldLow];
}

-(void)setLowValues:(CPTMutableNumericData *)newValues 
{
    [self cacheNumbers:newValues forField:CPTTradingRangePlotFieldLow];
}

-(CPTMutableNumericData *)closeValues 
{
    return [self cachedNumbersForField:CPTTradingRangePlotFieldClose];
}

-(void)setCloseValues:(CPTMutableNumericData *)newValues 
{
    [self cacheNumbers:newValues forField:CPTTradingRangePlotFieldClose];
}


@end
