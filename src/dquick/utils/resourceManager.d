module dquick.utils.resourceManager;

import std.string;
import std.stdio;
import std.algorithm;

public import std.variant;

// TODO add assert on destruction if some resources aren't released, it's considered like a leak
// TODO add assert on multiple release of an non existing resource

// TODO regarder s'il ne faut pas enlever le load du IResource pour que le chargement soit plus simple

class ResourceManager
{
public:
	@property void	maximumWeight(int weight)
	{
		mMaximumWeight = weight;
		shrink();
	}
	@property int	maximumWeight()	{return mMaximumWeight;}

	T	getResource(T : IResource)(string filePath, Variant[] options = null)
	{
		IResource*	resource;
		T	instance;

		resource = (filePath in mUsedResources);
		if (resource !is null)
		{
			instance = cast(T)(*resource);
			instance.incrementCounter();
			return instance;
		}
		else
		{
			ptrdiff_t	i;
			for (i = mCachedResources.length - 1; i != -1; i--)
			{
				if (mCachedResources[i].filePath == filePath)
				{
					instance = cast(T)mCachedResources[i];
					mCachedResources.remove(i);	// remove it from cache
					break;
				}
			}
			if (i == -1)
			{
				instance = new T;
				instance.load(filePath, options);
				mCurrentWeight += instance.weight;
				shrink();
			}
		}

		instance.incrementCounter();
		mUsedResources[filePath] = instance;

		return instance;
	}

	void	releaseResource(T : IResource)(T resource)
	{
		resource.decrementCounter();
		if (resource.counter() == 0)
		{
			if (mUsedResources.remove(resource.filePath))
			{
				if (mCurrentWeight + resource.weight <= mMaximumWeight)
				{
					mCachedResources ~= resource;
				}
				else
				{
					mCurrentWeight -= resource.weight;
					destroy(resource);
				}
			}
		}
	}

	void	dump()
	{
		writeln("====================");
		writeln("Resource manager:");
		writefln("Total Weight : %d", mCurrentWeight);
		writefln("Number of used resources : %d", mUsedResources.length);
		writefln("Number of cached resources : %d", mCachedResources.length);
		writeln("Used resources:");
		foreach (filePath, resource; mUsedResources)
		{
			writefln("Resource \"%s\" counter: %d weight : %d", filePath, resource.counter, resource.weight);
		}
		writeln("Cached resources:");
		foreach (resource; mCachedResources)
		{
			writefln("Resource \"%s\" weight : %d", resource.filePath, resource.weight);
		}

	}

protected:
	void	shrink()
	{
		while (mCurrentWeight > mMaximumWeight && mCachedResources.length)
		{
			mCurrentWeight -= mCachedResources[0].weight;
			mCachedResources.remove(0);
		}
	}

	int					mMaximumWeight;
	int					mCurrentWeight;
	IResource[string]	mUsedResources;
	IResource[]			mCachedResources;	// Used as FIFO, Older resources are removed first. 
}

// WARNING Please not that all resources that sharing the same filePath will be affected by methods modifiers like load.
// WARNING No copy on write is implemented for the moment
interface IResource
{
	void	load(string filePath, Variant[] options);	/// First parameter will always be a string containing the FilePath (added by the ResourceManager), because it have to be registered. You have to throw an Exception if load failed.

	@property string	filePath();
	@property int		weight();
	void				incrementCounter();
	void				decrementCounter();
	@property size_t	counter();
}

mixin template ResourceBase()
{
public:
	string	filePath() {return mFilePath;}
	int		weight() {return mWeight;}

//protected:
	void				incrementCounter() {mCounter++;}
	void				decrementCounter() {mCounter--;}
	@property size_t	counter() {return mCounter;}

protected:
	string	mFilePath;
	size_t	mCounter;
	int		mWeight;
}

private:
class ResourceTest : IResource
{
	mixin ResourceBase;

public:
	void	load(string filePath, Variant[] options = null)
	{
		assert(options == null);
		mFilePath = filePath;
	}
}

unittest
{
	ResourceManager	manager = new ResourceManager();

	ResourceTest	r1 = manager.getResource!ResourceTest("toto");

	manager.dump();
	manager = null;
}
