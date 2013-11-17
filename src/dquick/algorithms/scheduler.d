module dquick.algorithms.scheduler;

import dquick.algorithms.weak;
import std.container;
import core.thread;
import core.time;
import core.atomic;
import core.sync.condition;

class Scheduler
{
	/** Delegate called every time a task is executed.
	 * Params:
	 * 		time =	Time since first execution of this task;
	 * 		step =	Time since last execution of this task.
	 * 		iter =	Repetition of this task (1 for first execution). 		
	 */
	alias void delegate(Duration time, Duration step, ulong iter) Task;
	
	this()
	{
		mCondition = new Condition(new Mutex());
		mRunThread = new Thread(&this.run);
		mRunThread.start();
		
		msSchedulers ~= this;
	}
	
	~this()
	{
		atomicStore(mDone, true);
		mCondition.notifyAll();
		mRunThread.join();
	}
	
	/** Adds a task.
	 * Params:
	 * 		relStart =		Time at which the task will be executed the first time. It is relative to "now".
	 * 		step =			Step between subsequent calls.
	 * 		iterations =	Total number of task repetitions. Pass 0, if task has to be executed until program exists.
	 *		task = 			Delegate to be called. Scheduler will keep weak reference to it.
	 */
	void addTask(Duration relStart, Duration step, ulong iterations, Task task)
	{
		TaskData td;
		td.nextExecution = relStart + TickDuration.currSystemTick;
		td.step = step;
		td.iterationCounter = 0;
		td.desiredIterations = iterations;
		td.task = weak(task);
		td.infinite = (iterations == 0);
		synchronized(this)
		{
			mTasks.insert(td);
		}
		
		mCondition.notifyAll();
	}
	
	static void terminateAll()
	{
		foreach(sched; msSchedulers)
			sched.destroy();
		msSchedulers = null;
	}
	
	private
	{
		struct TaskData
		{
			Duration firstExecution;
			Duration nextExecution;
			Duration step;
			ulong iterationCounter;
			ulong desiredIterations;
			Weak!Task task;
			bool infinite;
		}
		
		BinaryHeap!(Array!TaskData, "a.nextExecution > b.nextExecution") mTasks;
		shared bool mDone;
		Thread mRunThread;
		Condition mCondition;
		
		void run()
		{
			while(!mDone)
			{
				Duration waitFor;					
				while(!mTasks.empty)
				{
					TaskData next;
					synchronized(this)
						next = mTasks.front;
					
					auto now = cast(Duration)TickDuration.currSystemTick;
					if(next.nextExecution < now)
					{
						synchronized(this)
						{
							mTasks.removeFront();
						}
						
						if(!next.iterationCounter)
							next.firstExecution = now;
						++next.iterationCounter;
						Task dlg = next.task.target;
						if(dlg.ptr is null)
							continue;
						dlg(now - next.firstExecution, next.step, next.iterationCounter);
						if(next.infinite || next.iterationCounter < next.desiredIterations)
						{
							next.nextExecution = now + next.step;
							synchronized(this)
							{
								mTasks.insert(next);
							}
						}
					}
					else
					{
						waitFor = next.nextExecution - now;
						break;
					}
				}
				
				synchronized(mCondition.mutex)
				{
					if(waitFor > Duration.zero)
						mCondition.wait(waitFor);
					else
						mCondition.wait();
				}
			}
		}
		
		static Scheduler[] msSchedulers;
	}
}
