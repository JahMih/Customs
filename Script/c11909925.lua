-- Snake-Eyes Execute Dragon
local s,id=GetID()
function s.initial_effect(c)
    -- Synchro Summon
    Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsType,TYPE_TUNER),1,1,Synchro.NonTuner(nil),1,99)
    c:EnableReviveLimit()
    
    -- First Effect: Place face-up monster as Continuous Spell
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_LEAVE_GRAVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)  -- Quick Effect
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetHintTiming(0,TIMING_MAIN)  -- Ensures it's available Main Phase
    e1:SetCountLimit(1,id) -- Ensures the effect can only be activated once per turn
    e1:SetCondition(s.first_condition)
    e1:SetTarget(s.first_target)
    e1:SetOperation(s.first_operation)
    c:RegisterEffect(e1)
    
    -- Initialize global variables for turn tracking
    aux.GlobalCheck(s,function()
        s[0]=-1 -- Last turn the effect was activated (initialized to -1)
        s[1]=false -- Lock status for the effect
    end)
    
    -- Second Effect: Destroy a monster and a Continuous Spell
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)  -- Quick Effect
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMING_BATTLE_START|TIMING_BATTLE_END)
    e2:SetCountLimit(1,id+1) -- Separate count for the second effect
    e2:SetCondition(function() return Duel.IsBattlePhase() end)
    e2:SetTarget(s.second_target)
    e2:SetOperation(s.second_operation)
    c:RegisterEffect(e2)
end

-- First Effect: Place face-up monster as Continuous Spell
function s.first_condition(e,tp,eg,ep,ev,re,r,rp)
    local ct=Duel.GetTurnCount()
    -- Allow activation if:
    -- 1. It's the Main Phase (either PHASE_MAIN1 or PHASE_MAIN2)
    -- 2. The effect wasn't activated this turn AND
    -- 3. The effect wasn't activated in the last turn
    return (Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2) and
           (ct~=s[0]+1)
end
function s.first_target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() or
               chkc:IsLocation(LOCATION_GRAVE) and chkc:IsType(TYPE_MONSTER)
    end
    if chk==0 then
        return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) or 
               Duel.IsExistingTarget(Card.IsType,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,TYPE_MONSTER)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,
        function(c)
            return c:IsFaceup() or (c:IsType(TYPE_MONSTER) and c:IsLocation(LOCATION_GRAVE))
        end,
        tp,
        LOCATION_MZONE+LOCATION_GRAVE,
        LOCATION_MZONE+LOCATION_GRAVE,
        1,
        1,
        nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.first_operation(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        -- Place the target as a Continuous Spell in the S/T zone
        Duel.MoveToField(tc,tp,tc:GetControler(),LOCATION_SZONE,POS_FACEUP,true)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetCode(EFFECT_CHANGE_TYPE)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
        e1:SetValue(TYPE_CONTINUOUS+TYPE_SPELL)
        tc:RegisterEffect(e1)
        
        -- Update turn tracking to lock the effect for the next turn
        s[0]=Duel.GetTurnCount()
    end
end

-- Second Effect: Destroy a monster and a Continuous Spell

function s.second_target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then
        return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) and
               Duel.IsExistingTarget(Card.IsType,tp,LOCATION_SZONE,LOCATION_SZONE,1,nil,TYPE_CONTINUOUS+TYPE_SPELL)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g1=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g2=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_SZONE,LOCATION_SZONE,1,1,nil,TYPE_CONTINUOUS+TYPE_SPELL)
    g1:Merge(g2)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,2,0,0)
end
function s.second_operation(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    if g then
        Duel.Destroy(g,REASON_EFFECT)
    end
end
