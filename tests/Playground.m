//
// cocos2d for iphone
// main file
//

#import "chipmunk.h"

#import "Scene.h"
#import "Layer.h"
#import "Director.h"
#import "Sprite.h"
#import "IntervalAction.h"
#import "InstantAction.h"
#import "Label.h"
#import "MenuItem.h"
#import "Menu.h"

#import "OpenGL_Internal.h"

#import "Playground.h"


static void
eachShape(void *ptr, void* unused)
{
	cpShape *shape = (cpShape*) ptr;
	Sprite *sprite = shape->data;
	if( sprite ) {
		cpBody *body = shape->body;
		[sprite setPosition: cpv( body->p.x, body->p.y)];
		[sprite setRotation: RADIANS_TO_DEGREES( -body->a )];
	}
}

@implementation Layer1
-(void) addNewSpriteX: (float)x y:(float)y
{
	Sprite *sprite = [Sprite spriteFromFile:@"grossini.png"];
	[self add: sprite];
	sprite.scale = 0.1;
	
	[sprite do: [ScaleTo actionWithDuration:0.2 scale:1.0]];
	
	sprite.position = cpv(x,y);
	
	int num = 4;
	cpVect verts[] = {
		cpv(-24,-54),
		cpv(-24, 54),
		cpv( 24, 54),
		cpv( 24,-54),
	};
	
	cpBody *body = cpBodyNew(1.0, cpMomentForPoly(1.0, num, verts, cpvzero));
	body->p = cpv(x, y);
	cpSpaceAddBody(space, body);
	
	cpShape* shape = cpPolyShapeNew(body, num, verts, cpvzero);
	shape->e = 0.5; shape->u = 1.5;
	shape->collision_type = 1;
	shape->data = sprite;
	cpSpaceAddShape(space, shape);
	
}
-(id) init
{
	[super init];
	
	isTouchEnabled = YES;
	isAccelerometerEnabled = YES;
	
	CGRect wins = [[Director sharedDirector] winSize];
	cpInitChipmunk();
	
	cpBody *staticBody = cpBodyNew(INFINITY, INFINITY);
	space = cpSpaceNew();
	cpSpaceResizeStaticHash(space, 20.0, 999);
	space->gravity = cpv(0, 0);

	cpShape *shape;
	
	// bottom
	shape = cpSegmentShapeNew(staticBody, cpv(0,0), cpv(wins.size.width,0), 0.0f);
	shape->e = 1.0; shape->u = 1.0;
	cpSpaceAddStaticShape(space, shape);

	// top
	shape = cpSegmentShapeNew(staticBody, cpv(0,wins.size.height), cpv(wins.size.width,wins.size.height), 0.0f);
	shape->e = 1.0; shape->u = 1.0;
	cpSpaceAddStaticShape(space, shape);

	// left
	shape = cpSegmentShapeNew(staticBody, cpv(0,0), cpv(0,wins.size.height), 0.0f);
	shape->e = 1.0; shape->u = 1.0;
	cpSpaceAddStaticShape(space, shape);

	// right
	shape = cpSegmentShapeNew(staticBody, cpv(wins.size.width,0), cpv(wins.size.width,wins.size.height), 0.0f);
	shape->e = 1.0; shape->u = 1.0;
	cpSpaceAddStaticShape(space, shape);
	
	[self addNewSpriteX: 200 y:200];

	return self;
}

-(void) onEnter
{
	[super onEnter];
	[self schedule: @selector(step)];

	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 100)];
}

-(void) onExit
{
	[self unschedule:@selector(step)];
	[super onExit];
}

-(void) step
{
	int steps = 2;
	cpFloat dt = 1.0/30.0/(cpFloat)steps;
	
	for(int i=0; i<steps; i++){
		cpSpaceStep(space, dt);
		cpSpaceHashEach(space->activeShapes, &eachShape, nil);
		cpSpaceHashEach(space->staticShapes, &eachShape, nil);
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];	
	CGPoint location = [touch locationInView: [touch view]];
	
	location = [[Director sharedDirector] convertCoordinate: location];
	
	[self addNewSpriteX: location.x y:location.y];
	
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	cpVect v = cpv( acceleration.x, acceleration.y);
	v = cpvnormalize(v);
	
	if (acceleration.x || acceleration.y)
		space->gravity = cpvmult(v, 100);
}
@end

// CLASS IMPLEMENTATIONS
@implementation AppController

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	// before creating any layer, set the landscape mode
//	[[Director sharedDirector] setLandscape: YES];

		
	Scene *scene = [Scene node];

	[scene add: [Layer1 node] z:0];

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	
	[[Director sharedDirector] runScene: scene];
}

@end