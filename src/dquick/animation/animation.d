module dquick.animation.animation;

import dquick.algorithms.scheduler;
import core.time;

interface IAnimation
{
	@property bool running() const;
	@property void running(bool r);
	
	@property Duration duration() const;
	@property void duration(Duration dur);
	
	// time - time since animation was started update
	void update(Duration time);
	
	@property static Scheduler scheduler()
	{
		return msScheduler;
	}
	
	private static Scheduler msScheduler;
	
	private shared static this()
	{
		msScheduler = new Scheduler();
	}
}

interface IAnimationGroup : IAnimation
{
	void addChild(IAnimation animation);
	Duration setMaxDuration();
}

class LinearAnimation(T) : IAnimation
{
	alias void delegate(T) Setter;
	
	this(Setter setter)
	{
		this(null, setter);
	}
	
	this(IAnimationGroup parent, Setter setter)
	{
		mHasTask = (parent is null);
		mSetter = setter;
		if(parent !is null)
			parent.addChild(this);
	}
	
	@property T from() const{ return mFrom; }
	@property void from(T val){ mFrom = val; }
	
	@property T to() const{ return mTo; }
	@property void to(T val){ mTo = val; }
	
	bool running() const{ return mIsRunning; }
	void running(bool r)
	{
		if(r == mIsRunning)
			return;		
		mIsRunning = r;
		if(mIsRunning)
		{
			mStart = cast(Duration)TickDuration.currSystemTick;
			mCurrTime = mStart;
			if(mHasTask)
			{
				mTask = new AnimTask(this);
				IAnimation.scheduler.addTask(Duration.zero, animationUpdateDelta, 0, &mTask.execute);
			}
		}
		else if(mHasTask)
		{
			mTask.destroy();
			mTask = null;
		}
	}
	
	Duration duration() const{ return mDuration; }
	void duration(Duration dur)
	{
		mDuration = dur;
		if(mIsRunning)
			updateValue();
	}
	
	void update(Duration time)
	{
		if(!mIsRunning)
			return;
		mCurrTime = time;
		updateValue();
	}
	
	private
	{
		T mFrom, mTo;
		Duration mDuration;
		Setter mSetter;
		bool mHasTask;
		
		bool mIsRunning;
		Duration mStart, mCurrTime;
		scope AnimTask mTask;
		
		void updateValue()
		{			
			double t = cast(double)(mCurrTime.total!"usecs")/mDuration.total!"usecs";
			
			if(t < 0)
				throw new Exception("Invalid value of mCurrTime!");
			else if(t > 1)
			{
				mSetter(mTo);
				running = false;
			}
			else
			{
				T val = cast(T)(mFrom*(1.0-t) + mTo*t);
				mSetter(val);
			}
		}
	}
}

class ParallelAnimation : IAnimationGroup
{	
	this(IAnimationGroup parent = null)
	{
		mHasTask = (parent is null);
		if(parent !is null)
			parent.addChild(this);
	}
	
	bool running() const{ return mIsRunning; }
	void running(bool r)
	{
		if(r == mIsRunning)
			return;
		mIsRunning = r;
		foreach(anim; mChildren)
			anim.running = mIsRunning;
		if(mIsRunning)
		{
			mCurrTime = Duration.zero;
			
			if(mHasTask)
			{
				mTask = new AnimTask(this);
				IAnimation.scheduler.addTask(Duration.zero, animationUpdateDelta, 0, &mTask.execute);
			}
		}
		else if(mHasTask)
		{
			mTask.destroy();
			mTask = null;
		}
	}
	
	Duration duration() const{ return mDuration; }
	void duration(Duration dur){ mDuration = dur; }
	
	void update(Duration time)
	{
		mCurrTime = time;
		if(mCurrTime > mDuration)
			running = false;
		else
		{
			foreach(anim; mChildren)
				anim.update(time);
		}
	}
	
	void addChild(IAnimation animation)
	{
		mChildren ~= animation;
	}
	
	Duration setMaxDuration()
	{
		if(mChildren.length == 0)
		{
			mDuration = Duration.zero;
			return mDuration;
		}
		
		foreach(i, anim; mChildren)
		{
			IAnimationGroup gr;
			if((gr = cast(IAnimationGroup)anim) !is null)
			{
				auto grDur = gr.setMaxDuration();
				if(i && mDuration < grDur)
					mDuration = grDur;
				else if(!i)
					mDuration = grDur;
			}
			else
			{
				if(i && mDuration < anim.duration)
					mDuration = anim.duration;
				else if(!i)
					mDuration = anim.duration;
			}
		}
		return mDuration;
	}
	
	private
	{
		IAnimation[] mChildren;
		Duration mDuration;
		bool mHasTask;
		
		bool mIsRunning;
		Duration mCurrTime;
		scope AnimTask mTask;
	}
}

class SequentialAnimation : IAnimationGroup
{
	this(IAnimationGroup parent = null)
	{
		mHasTask = (parent is null);
		if(parent !is null)
			parent.addChild(this);
	}
	
	bool running() const{ return mIsRunning; }
	void running(bool r)
	{
		if(r == mIsRunning)
			return;
		mIsRunning = r;
		if(mIsRunning)
		{
			mChildStart = Duration.zero;
			mCurrIteration = 0;
			mCurrTime = Duration.zero;
			
			if(mChildren.length)
				mChildren[0].running = true;
			
			if(mHasTask)
			{
				mTask = new AnimTask(this);
				IAnimation.scheduler.addTask(Duration.zero, animationUpdateDelta, 0, &mTask.execute);
			}
		}
		else if(mHasTask)
		{
			if(mCurrIteration < mChildren.length)
				mChildren[mCurrIteration].running = false;
			
			mTask.destroy();
			mTask = null;
		}
		
		mChildStart = Duration.zero;
		mCurrIteration = 0;
		mCurrTime = Duration.zero;
	}
	
	Duration duration() const{ return mDuration; }
	void duration(Duration dur){ mDuration = dur; }
	
	void update(Duration time)
	{
		mCurrTime = time;
		
		if(mCurrTime > mDuration)
		{
			running = false;
			return;
		}
		
		mChildren[mCurrIteration].update(time - mChildStart);
		
		if(!mChildren[mCurrIteration].running)
		{
			++mCurrIteration;
			if(mCurrIteration == mChildren.length)
				running = false;
			else
			{
				mChildStart = mCurrTime;
				mChildren[mCurrIteration].running = true;
			}
		}
	}
	
	Duration setMaxDuration()
	{
		mDuration = Duration.zero;
		foreach(anim; mChildren)
		{
			IAnimationGroup gr;
			if((gr = cast(IAnimationGroup)anim) !is null)
				mDuration += gr.setMaxDuration();
			else
				mDuration += anim.duration;
		}
		return mDuration;
	}
	
	void addChild(IAnimation animation)
	{
		mChildren ~= animation;
	}
	
	private
	{
		IAnimation[] mChildren;
		Duration mDuration;
		bool mHasTask;
		
		bool mIsRunning;
		Duration mChildStart;
		Duration mCurrTime;
		uint mCurrIteration;
		scope AnimTask mTask;
	}
}

class LoopedAnimation : IAnimationGroup
{
	static immutable uint infinite = 0xffffffff;
	
	this(IAnimationGroup parent = null)
	{
		mHasTask = (parent is null);
		if(parent !is null)
			parent.addChild(this);
	}
	
	bool running() const{ return mChild !is null ? mChild.running : false; }
	void running(bool r)
	{
		if(r == mChild.running)
			return;
		mChild.running = r;
		if(r)
		{
			mStart = Duration.zero;
			mLoopCounter = 0;
			if(mHasTask)
			{
				mTask = new AnimTask(this);
				IAnimation.scheduler.addTask(Duration.zero, animationUpdateDelta, 0, &mTask.execute);
			}
		}
		else if(mHasTask)
		{
			mTask.destroy();
			mTask = null;
		}
	}
	
	Duration duration() const
	{
		if(mNumLoops == infinite)
			return Duration.max;
		return mChild !is null ? mChild.duration : Duration.zero;
	}
	
	void duration(Duration dur){ if(mChild !is null) mChild.duration = dur; }
	
	@property uint loops() const{ return mNumLoops; }
	@property void loops(uint n){ mNumLoops = n; }
	
	void update(Duration time)
	{
		if(mChild !is null)
		{
			mChild.update(time - mStart);
		
			if(!mChild.running)
			{
				if(mNumLoops != infinite)
					++mLoopCounter;
				if(mLoopCounter == mNumLoops)
					running = false;
				else
				{
					mStart = time;
					mChild.running = true;
				}
			}
		}
	}
	
	void addChild(IAnimation animation)
	{
		if(mChild is null)
			mChild = animation;
		else
			throw new Exception("LoopedAnimation can have only one child!");
	}
	
	Duration setMaxDuration()
	{			
		Duration dur;
		IAnimationGroup gr = cast(IAnimationGroup)mChild;
		if(gr !is null)
			dur = gr.setMaxDuration();
		else if(gr !is null)
			dur = mChild.duration;
		
		if(mNumLoops == infinite)
			return Duration.max;
		return dur*mNumLoops;
	}
	
	private
	{
		IAnimation mChild;
		bool mHasTask;
		AnimTask mTask;
		uint mNumLoops;
		
		Duration mStart;
		uint mLoopCounter;
	}
}

private
{
	shared Duration animationUpdateDelta = dur!"msecs"(1000/60);

	// adapter to use IAnimation classes with Scheduler.
	// call destroy() to remove AnimTask from Scheduler (weak references).
	class AnimTask
	{
		this(IAnimation animation)
		{
			mAnimation = animation;
		}
		
		void execute(Duration time, Duration step, ulong iteration)
		{
			mAnimation.update(time);
		}
		
		private IAnimation mAnimation;
	}
}
